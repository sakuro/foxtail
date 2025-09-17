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
      report << "**Conditional matches**: Results that match after normalizing whitespace characters (CLDR uses non-breaking spaces U+00A0, Node.js uses regular spaces U+0020)"
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
