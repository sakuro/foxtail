# frozen_string_literal: true

# Generates Node.js Intl compatibility reports
class NodeIntlReporter
  def initialize(results)
    @results = results
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
    report << "## Summary"
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
    report << "| Matches | #{total_matches} | #{match_percentage}% |"
    if conditional_matches > 0
      report << "| - Exact matches | #{exact_matches} | #{total.zero? ? 0.0 : (Float(exact_matches) / total * 100).round(1)}% |"
      report << "| - Conditional matches | #{conditional_matches} | #{total.zero? ? 0.0 : (Float(conditional_matches) / total * 100).round(1)}% |"
    end
    report << "| Mismatches | #{mismatches} | #{mismatch_percentage}% |"
    report << "| Errors | #{errors} | #{error_percentage}% |"
    report << ""
    if conditional_matches > 0
      report << ""
      report << "**Conditional matches**: Results that match after normalizing whitespace characters (CLDR uses non-breaking spaces U+00A0, Node.js uses regular spaces U+0020)"
      report << ""
    end
    report << "*Total test cases: #{total}*"
    report << ""

    # Category breakdown
    report << "## Category Breakdown"
    report << ""
    categories = group_by_category
    report << "| Category | Matches | Total | Percentage |"
    report << "|----------|---------|-------|------------|"

    categories.each do |category, results|
      total_cat = results.size
      matches_cat = results.count(&:success?)
      percentage_cat = total_cat.zero? ? 0.0 : (Float(matches_cat) / total_cat * 100).round(1)

      status_icon = if percentage_cat == 100.0
                      "✅"
                    else
                      percentage_cat >= 90.0 ? "⚠️" : "❌"
                    end

      report << "| #{status_icon} #{category.capitalize} | #{matches_cat} | #{total_cat} | #{percentage_cat}% |"
    end

    report << ""

    # Detailed results for mismatches
    mismatches = @results.select {|r| r.status == :mismatch }
    if mismatches.any?
      report << "## Mismatches"
      report << ""

      mismatches.each do |result|
        report << "### #{result.id}"
        report << ""
        report << "- **Value**: #{result.value}"
        report << "- **Locale**: #{result.locale}"
        report << "- **Options**: #{result.options.inspect}"
        report << "- **Foxtail**: `#{result.foxtail_result}`"
        report << "- **Node.js**: `#{result.node_result}`"
        report << ""
      end
    end

    # Errors
    errors = @results.select {|r| r.status == :error }
    if errors.any?
      report << "## Errors"
      report << ""

      errors.each do |result|
        report << "### #{result.id}"
        report << ""
        report << "- **Value**: #{result.value}"
        report << "- **Locale**: #{result.locale}"
        report << "- **Options**: #{result.options.inspect}"
        report << "- **Error**: #{result.error}"
        report << ""
      end
    end

    report.join("\n")
  end

  private def group_by_category
    @results.group_by do |result|
      case result.id
      when /^decimal_/
        "decimal"
      when /^currency_/
        "currency"
      when /^percent_/
        "percent"
      when /^scientific_/
        "scientific"
      when /^datetime_/
        "datetime"
      else
        "other"
      end
    end
  end
end
