# frozen_string_literal: true

# Generates Node.js Intl compatibility reports
class NodeIntlReporter
  def initialize(results)
    @results = results
    @number_results = results.select {|r| r.id.start_with?("number_") }
    @datetime_results = results.select {|r| r.id.start_with?("datetime_") }
  end

  # Generate summary statistics
  def generate_summary_report
    total = @results.size
    matches = @results.count(&:success?)
    percentage = total.zero? ? 0.0 : (Float(matches) / total * 100).round(1)

    "Node.js Intl Compatibility: #{matches}/#{total} matches (#{percentage}%)"
  end

  # Generate detailed markdown report
  def generate_markdown_report
    report = []
    report << "# Node.js Intl Compatibility Report"
    report << ""

    # Timezone environment investigation
    report.concat(generate_timezone_investigation)
    report << ""

    # Overall summary
    report.concat(generate_overall_summary)
    report << ""

    # NumberFormat section
    report.concat(generate_numberformat_section)
    report << ""

    # DateTimeFormat section
    report.concat(generate_datetimeformat_section)

    report.join("\n")
  end

  private def generate_timezone_investigation
    require_relative "../../lib/foxtail/cldr/formatter/local_timezone_detector"

    report = []
    report << "## Test Environment Timezone Investigation"
    report << ""
    report << "This section provides information about the timezone environment during testing to help interpret results."
    report << ""

    # Current timezone detection
    detector = Foxtail::CLDR::Formatter::LocalTimezoneDetector.new
    detected = detector.detect

    # Get current Node.js timezone
    current_node_timezone = %x(node -e "
      const resolved = Intl.DateTimeFormat().resolvedOptions();
      console.log(resolved.timeZone);
    " 2>/dev/null).strip
    current_node_timezone = "ERROR" if current_node_timezone.empty?

    report << "### Current Environment"
    report << ""
    report << "| Setting | Value |"
    report << "|---------|-------|"
    report << "| ENV['TZ'] | `#{ENV.fetch("TZ", "not set").inspect}` |"
    report << "| Time.now.zone | `#{Time.now.zone.inspect}` |"
    report << "| Time.now.utc_offset | #{Time.now.utc_offset} seconds (#{format_utc_offset(Time.now.utc_offset)}) |"
    report << "| Foxtail detected timezone | `#{detected.id}` |"
    report << "| Foxtail detected offset | #{detected.offset_seconds} seconds (#{detected.offset_string}) |"
    report << "| Node.js resolved timezone | `#{current_node_timezone}` |"
    report << ""

    # Test various TZ environment formats
    test_formats = %w[UTC UTC+0 UTC+0:00 UTC-0 UTC-0:00 GMT GMT+0 GMT-0 America/New_York Europe/London Asia/Tokyo]

    report << "### TZ Environment Variable Tests"
    report << ""
    report << "Testing how different TZ environment variable formats are detected:"
    report << ""
    report << "| TZ Format | Ruby Time.zone | Ruby UTC Offset | Foxtail Detection | Foxtail Offset | Node.js Resolved |"
    report << "|-----------|----------------|-----------------|-------------------|----------------|------------------|"

    test_formats.each do |tz_format|
      # Test in a subprocess to avoid affecting current environment
      result = %x(TZ=#{tz_format} ruby -e "
        require_relative 'lib/foxtail/cldr/formatter/local_timezone_detector'
        detector = Foxtail::CLDR::Formatter::LocalTimezoneDetector.new
        detected = detector.detect
        puts [Time.now.zone.inspect, Time.now.utc_offset, detected.id.inspect, detected.offset_seconds].join('|')
      " 2>/dev/null).strip

      # Get Node.js timezone detection
      node_result = %x(TZ=#{tz_format} node -e "
        const date = new Date();
        const resolved = Intl.DateTimeFormat().resolvedOptions();
        console.log(resolved.timeZone);
      " 2>/dev/null).strip

      if result.empty?
        report << "| `#{tz_format}` | ERROR | ERROR | ERROR | ERROR | #{node_result.empty? ? "ERROR" : node_result} |"
      else
        ruby_zone, ruby_offset, foxtail_id, foxtail_offset = result.split("|")
        ruby_offset_formatted = format_utc_offset(ruby_offset.to_i)
        foxtail_offset_formatted = format_utc_offset(foxtail_offset.to_i)
        node_timezone = node_result.empty? ? "ERROR" : node_result
        report << "| `#{tz_format}` | #{ruby_zone} | #{ruby_offset} (#{ruby_offset_formatted}) | #{foxtail_id} | #{foxtail_offset} (#{foxtail_offset_formatted}) | #{node_timezone} |"
      end
    end

    report << ""
    report << "**Note**: Discrepancies between Ruby's timezone detection and Foxtail's detection may affect datetime formatting compatibility results."

    report
  end

  private def format_utc_offset(seconds)
    hours = seconds / 3600
    minutes = (seconds % 3600) / 60
    sign = seconds >= 0 ? "+" : "-"
    "%s%02d:%02d" % [sign, hours.abs, minutes.abs]
  end

  private def generate_overall_summary
    report = []
    report << "## Overall Summary"
    report << ""

    # Overall statistics
    total = @results.size
    exact_matches = @results.count {|r| r.status == :match }
    conditional_matches = @results.count {|r| r.status == :conditional_match }
    total_matches = exact_matches + conditional_matches
    mismatches = @results.count {|r| r.status == :mismatch }
    errors = @results.count {|r| r.status == :error }

    match_percentage = total.zero? ? 0.0 : (Float(total_matches) / total * 100).round(1)
    mismatch_percentage = total.zero? ? 0.0 : (Float(mismatches) / total * 100).round(1)
    error_percentage = total.zero? ? 0.0 : (Float(errors) / total * 100).round(1)

    report << "| Metric | Count | Percentage |"
    report << "|--------|------:|-----------:|"
    report << "| Total Tests | #{total} | 100.0% |"
    report << "| Matches | #{total_matches} | #{match_percentage}% |"
    if conditional_matches > 0
      report << "| - Exact matches | #{exact_matches} | #{total.zero? ? 0.0 : (Float(exact_matches) / total * 100).round(1)}% |"
      report << "| - Conditional matches | #{conditional_matches} | #{total.zero? ? 0.0 : (Float(conditional_matches) / total * 100).round(1)}% |"
    end
    report << "| Mismatches | #{mismatches} | #{mismatch_percentage}% |"
    report << "| Errors | #{errors} | #{error_percentage}% |"

    if conditional_matches > 0
      report << ""
      report << "**Conditional matches**: Results that match after applying normalization rules:"
      report << ""
      report << "- **Whitespace normalization**: Foxtail uses Unicode whitespace characters per CLDR standards, while Node.js uses regular spaces"
      report << "  - **Foxtail**: Non-breaking space (U+00A0) and narrow no-break space (U+202F)"
      report << "  - **Node.js**: Regular space (U+0020)"
      report << "  - These are normalized to regular spaces for comparison as they represent equivalent spacing"
    end

    report
  end

  private def generate_numberformat_section
    generate_format_section("NumberFormat", @number_results)
  end

  private def generate_datetimeformat_section
    generate_format_section("DateTimeFormat", @datetime_results)
  end

  private def generate_format_section(format_name, results)
    report = []
    report << "## #{format_name} Compatibility"
    report << ""

    total = results.size
    exact_matches = results.count {|r| r.status == :match }
    conditional_matches = results.count {|r| r.status == :conditional_match }
    total_matches = exact_matches + conditional_matches
    mismatches = results.count {|r| r.status == :mismatch }
    errors = results.count {|r| r.status == :error }

    if total.zero?
      report << "No test cases found for #{format_name}."
      return report
    end

    match_percentage = (Float(total_matches) / total * 100).round(1)

    report << "| Metric | Count | Percentage |"
    report << "|--------|------:|-----------:|"
    report << "| Tests | #{total} | 100.0% |"
    report << "| Matches | #{total_matches} | #{match_percentage}% |"
    if conditional_matches > 0
      report << "| - Exact matches | #{exact_matches} | #{(Float(exact_matches) / total * 100).round(1)}% |"
      report << "| - Conditional matches | #{conditional_matches} | #{(Float(conditional_matches) / total * 100).round(1)}% |"
    end
    report << "| Mismatches | #{mismatches} | #{(Float(mismatches) / total * 100).round(1)}% |"
    report << "| Errors | #{errors} | #{(Float(errors) / total * 100).round(1)}% |"

    # Add mismatches for this format
    format_mismatches = results.select {|r| r.status == :mismatch }
    if format_mismatches.any?
      report << ""
      report << "### #{format_name} Mismatches"
      report << ""
      report << "<details>"
      report << "<summary>Show all #{format_mismatches.size} mismatches</summary>"
      report << ""

      format_mismatches.each do |result|
        report << "**#{result.id}**"
        report << "- Value: #{result.value}, Locale: #{result.locale}"
        report << "- Options: #{result.options.inspect}"
        report << "- Foxtail: `#{result.foxtail_result}`"
        report << "- Node.js: `#{result.node_result}`"
        report << ""
      end

      report << "</details>"
      report << ""
    end

    report
  end
end
