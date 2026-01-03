# frozen_string_literal: true

# Generates reports from compatibility test results
class CompatibilityReporter
  def initialize(results)
    @results = results
    @stats = calculate_statistics
  end

  # Generate summary report for console output
  def generate_summary_report
    perfect = @stats[:perfect_matches]
    total = @stats[:total_fixtures]
    perfect_pct = @stats[:perfect_percentage]
    functional = @stats[:functional_matches]
    functional_pct = @stats[:functional_percentage]

    "Fluent.js Compatibility: #{perfect}/#{total} perfect matches (#{perfect_pct}%), #{functional}/#{total} functional (#{functional_pct}%)"
  end

  # Generate detailed markdown report
  def generate_markdown_report
    <<~MARKDOWN
      # Fluent.js Compatibility Report

      ## Summary

      #{format_overall_stats_markdown}

      ## Category Breakdown

      #{format_category_breakdown_markdown}

      #{format_results_by_status_markdown}
    MARKDOWN
  end

  private def calculate_statistics
    total = @results.length
    perfect = @results.count(&:success?)
    partial = @results.count(&:partial_success?)
    functional = @results.count(&:functional_success?)
    differences = @results.count(&:difference?)
    failures = @results.count(&:failure?)
    known_incompatible = @results.count {|r| r.status == :known_incompatibility }

    structure_results = @results.select {|r| r.category == :structure }
    reference_results = @results.select {|r| r.category == :reference }

    {
      total_fixtures: total,
      perfect_matches: perfect,
      partial_matches: partial,
      functional_matches: functional,
      content_differences: differences,
      parsing_failures: failures,
      known_incompatibilities: known_incompatible,
      perfect_percentage: total > 0 ? (Float(perfect) / total * 100).round(1) : 0,
      functional_percentage: total > 0 ? (Float(functional) / total * 100).round(1) : 0,
      structure_stats: calculate_category_stats(structure_results),
      reference_stats: calculate_category_stats(reference_results)
    }
  end

  private def calculate_category_stats(results)
    total = results.length
    perfect = results.count(&:success?)
    functional = results.count(&:functional_success?)

    {
      total:,
      perfect:,
      functional:,
      perfect_percentage: total > 0 ? (Float(perfect) / total * 100).round(1) : 0,
      functional_percentage: total > 0 ? (Float(functional) / total * 100).round(1) : 0
    }
  end

  # Markdown formatting methods
  private def format_overall_stats_markdown
    <<~MARKDOWN
      | Metric | Count | Percentage |
      |--------|------:|-----------:|
      | Perfect matches | #{@stats[:perfect_matches]} | #{@stats[:perfect_percentage]}% |
      | Partial matches | #{@stats[:partial_matches]} | #{(Float(@stats[:partial_matches]) / @stats[:total_fixtures] * 100).round(1)}% |
      | Content differences | #{@stats[:content_differences]} | #{(Float(@stats[:content_differences]) / @stats[:total_fixtures] * 100).round(1)}% |
      | Parsing failures | #{@stats[:parsing_failures]} | #{(Float(@stats[:parsing_failures]) / @stats[:total_fixtures] * 100).round(1)}% |
      | Known incompatibilities | #{@stats[:known_incompatibilities]} | #{(Float(@stats[:known_incompatibilities]) / @stats[:total_fixtures] * 100).round(1)}% |

      *Total fixtures: #{@stats[:total_fixtures]}*
    MARKDOWN
  end

  private def format_category_breakdown_markdown
    structure_stats = @stats[:structure_stats]
    reference_stats = @stats[:reference_stats]

    <<~MARKDOWN
      | Category | Perfect | Functional | Total |
      |----------|---------|------------|-------|
      | 📐 Structure | #{structure_stats[:perfect]} (#{structure_stats[:perfect_percentage]}%) | #{structure_stats[:functional]} (#{structure_stats[:functional_percentage]}%) | #{structure_stats[:total]} |
      | 📚 Reference | #{reference_stats[:perfect]} (#{reference_stats[:perfect_percentage]}%) | #{reference_stats[:functional]} (#{reference_stats[:functional_percentage]}%) | #{reference_stats[:total]} |
    MARKDOWN
  end

  private def format_results_by_status_markdown
    lines = []

    # Group by status
    perfect_matches = @results.select(&:success?)
    partial_matches = @results.select(&:partial_success?)
    content_differences = @results.select(&:difference?)
    parsing_failures = @results.select(&:failure?)
    known_incompatible = @results.select {|r| r.status == :known_incompatibility }

    # Perfect matches - separated by category
    if perfect_matches.any?
      structure_perfect = perfect_matches.select {|r| r.category == :structure }
      reference_perfect = perfect_matches.select {|r| r.category == :reference }

      if structure_perfect.any?
        if structure_perfect.length > 10
          lines << "<details>"
          lines << "<summary>✅ Structure perfect matches (#{structure_perfect.length})</summary>"
          lines << ""
          structure_perfect.each {|result| lines << "- #{result.name}" }
          lines << ""
          lines << "</details>"
        else
          lines << "### ✅ Structure perfect matches (#{structure_perfect.length})"
          lines << ""
          structure_perfect.each {|result| lines << "- #{result.name}" }
          lines << ""
        end
      end

      if reference_perfect.any?
        if reference_perfect.length > 10
          lines << "<details>"
          lines << "<summary>✅ Reference perfect matches (#{reference_perfect.length})</summary>"
          lines << ""
          reference_perfect.each {|result| lines << "- #{result.name}" }
          lines << ""
          lines << "</details>"
        else
          lines << "### ✅ Reference perfect matches (#{reference_perfect.length})"
          lines << ""
          reference_perfect.each {|result| lines << "- #{result.name}" }
          lines << ""
        end
      end
    end

    # Partial matches
    if partial_matches.any?
      lines << "### ⚡ Partial matches (#{partial_matches.length})"
      lines << ""
      lines << "> Structurally correct but minor differences (e.g., span positions)"
      lines << ""
      partial_matches.each {|result| lines << "- **#{result.category}**: #{result.name}" }
      lines << ""
    end

    # Content differences
    if content_differences.any?
      lines << "### ⚠️ Significant differences (#{content_differences.length})"
      lines << ""
      content_differences.each {|result| lines << "- **#{result.category}**: #{result.name}" }
      lines << ""
    end

    # Parsing failures
    if parsing_failures.any?
      lines << "### ❌ Parsing failures (#{parsing_failures.length})"
      lines << ""
      parsing_failures.each {|result| lines << "- **#{result.category}**: #{result.name} - `#{result.error}`" }
      lines << ""
    end

    # Known incompatibilities
    if known_incompatible.any?
      lines << "### 🚧 Known incompatibilities (#{known_incompatible.length})"
      lines << ""
      lines << "> These are intentional differences from fluent.js behavior"
      lines << ""
      known_incompatible.each {|result| lines << "- **#{result.category}**: #{result.name}" }
      lines << ""
    end

    lines.join("\n")
  end
end
