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
    percentage = total.zero? ? 0.0 : (matches.to_f / total * 100).round(1)

    "Node.js Intl Compatibility: #{matches}/#{total} matches (#{percentage}%)"
  end

  # Generate detailed markdown report
  def generate_markdown_report
    report = []
    report << "# Node.js Intl.NumberFormat Compatibility Report"
    report << ""
    report << "## Summary"
    report << ""

    # Overall statistics
    total = @results.size
    matches = @results.count(&:success?)
    mismatches = @results.count { |r| r.status == :mismatch }
    errors = @results.count { |r| r.status == :error }

    match_percentage = total.zero? ? 0.0 : (matches.to_f / total * 100).round(1)
    mismatch_percentage = total.zero? ? 0.0 : (mismatches.to_f / total * 100).round(1)
    error_percentage = total.zero? ? 0.0 : (errors.to_f / total * 100).round(1)

    report << "| Metric | Count | Percentage |"
    report << "|--------|------:|-----------:|"
    report << "| Matches | #{matches} | #{match_percentage}% |"
    report << "| Mismatches | #{mismatches} | #{mismatch_percentage}% |"
    report << "| Errors | #{errors} | #{error_percentage}% |"
    report << ""
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
      percentage_cat = total_cat.zero? ? 0.0 : (matches_cat.to_f / total_cat * 100).round(1)

      status_icon = percentage_cat == 100.0 ? "✅" : percentage_cat >= 90.0 ? "⚠️" : "❌"

      report << "| #{status_icon} #{category.capitalize} | #{matches_cat} | #{total_cat} | #{percentage_cat}% |"
    end

    report << ""

    # Detailed results for mismatches
    mismatches = @results.select { |r| r.status == :mismatch }
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
    errors = @results.select { |r| r.status == :error }
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

  private

  def group_by_category
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
      else
        "other"
      end
    end
  end
end