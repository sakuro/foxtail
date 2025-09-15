# frozen_string_literal: true

require "json"
require "open3"
require "pathname"
require_relative "../../lib/foxtail"

# Executes Node.js Intl.NumberFormat compatibility tests
class NodeIntlTester
  # Path to Node.js comparator script
  COMPARATOR_SCRIPT = Pathname.new(__dir__) / "comparator.js"
  private_constant :COMPARATOR_SCRIPT

  # Test result structure
  TestResult = Data.define(:id, :value, :locale, :options, :foxtail_result, :node_result, :status, :error) {
    def success?
      status == :match || status == :conditional_match
    end

    def failure?
      status == :mismatch || status == :error
    end

    def conditional_match?
      status == :conditional_match
    end

    def number_format?
      id.start_with?("number_")
    end

    def datetime_format?
      id.start_with?("datetime_")
    end
  }

  def initialize
    @number_test_cases = []
    @datetime_test_cases = []
  end

  # Generate comprehensive test cases
  def generate_test_cases
    @number_test_cases = []
    @datetime_test_cases = []

    # Number format test cases
    add_style_notation_combination_tests

    # DateTime format test cases
    add_datetime_format_tests

    {number: @number_test_cases, datetime: @datetime_test_cases}
  end

  # Run all generated test cases
  def test_all
    test_cases = generate_test_cases

    number_results = run_number_tests(test_cases[:number])
    datetime_results = run_datetime_tests(test_cases[:datetime])

    number_results + datetime_results
  end

  # Run Node.js comparisons for number test cases
  def run_number_tests(test_cases)
    # Prepare input for Node.js script (old format for backward compatibility)
    input_data = {
      test_cases: test_cases.map do |test_case|
        {
          id: test_case[:id],
          value: test_case[:value],
          locale: test_case[:locale],
          options: test_case[:options]
        }
      end
    }

    # Execute Node.js comparator
    node_results = execute_node_comparator(input_data)
    return [] unless node_results

    # Run Foxtail formatting and compare results
    compare_number_results(test_cases, node_results["results"] || [])
  end

  # Run Node.js comparisons for datetime test cases
  def run_datetime_tests(test_cases)
    # Prepare input for Node.js script (new format)
    input_data = {
      datetime_test_cases: test_cases.map do |test_case|
        {
          id: test_case[:id],
          value: test_case[:value],
          locale: test_case[:locale],
          options: test_case[:options]
        }
      end
    }

    # Execute Node.js comparator
    node_results = execute_node_comparator(input_data)
    return [] unless node_results

    # Run Foxtail formatting and compare results
    compare_datetime_results(test_cases, node_results["datetime_results"] || [])
  end

  private def add_style_notation_combination_tests
    # Test values for different scenarios
    test_values = [
      0,           # Zero
      1,           # Simple integer
      123,         # Three-digit number
      1234.56,     # Number with decimals
      123_456_789, # Large number
      0.000123,    # Small number
      -987.65      # Negative number
    ]

    # All valid style values
    styles = %w[decimal currency percent unit]

    # All valid notation values
    notations = %w[standard scientific engineering compact]

    # Test locales
    locales = %w[en-US ja-JP de-DE fr-FR]

    styles.each do |style|
      notations.each do |notation|
        test_values.each do |value|
          locales.each do |locale|
            # Build options based on style
            options = {style:, notation:}

            # Add required parameters for specific styles
            case style
            when "currency"
              options[:currency] = case locale
                                   when "ja-JP"
                                     "JPY"
                                   when "de-DE", "fr-FR"
                                     "EUR"
                                   else
                                     "USD"
                                   end
            when "unit"
              # Test multiple basic units and compound units
              case test_values.index(value) % 6
              when 0
                options[:unit] = "kilometer"
              when 1
                options[:unit] = "meter"
              when 2
                options[:unit] = "gram"
              when 3
                options[:unit] = "liter"
              when 4
                options[:unit] = "celsius"
              when 5
                options[:unit] = "kilometer-per-hour"
              end
              options[:unitDisplay] = "short"
            end

            # Generate unique ID
            id_parts = ["number", style, notation, locale.tr("-", "_"), value.to_s.gsub("-", "neg").tr(".", "_")]
            # Add unit name to ID for unit style
            if style == "unit" && options[:unit]
              id_parts << options[:unit].tr("-", "_")
            end
            id = id_parts.join("_")

            @number_test_cases << {
              id:,
              value:,
              locale:,
              options:
            }
          end
        end
      end
    end
  end

  private def add_datetime_format_tests
    # Test dates for different scenarios
    test_dates = [
      "2023-01-15T10:30:00Z",     # Standard datetime
      "2023-12-25T00:00:00Z",     # Christmas (year end)
      "2023-07-04T15:45:30Z",     # Mid-year with seconds
      "2023-02-14T23:59:59Z",     # Valentine's day, end of day
      "2024-02-29T12:00:00Z"      # Leap year date
    ]

    # Test locales
    locales = %w[en-US ja-JP de-DE fr-FR]

    # Date/Time style combinations
    styles = [
      {dateStyle: "full"},
      {dateStyle: "long"},
      {dateStyle: "medium"},
      {dateStyle: "short"},
      {timeStyle: "full"},
      {timeStyle: "long"},
      {timeStyle: "medium"},
      {timeStyle: "short"},
      {dateStyle: "medium", timeStyle: "short"},
      {dateStyle: "short", timeStyle: "medium"},
      {year: "numeric", month: "long", day: "numeric"},
      {weekday: "long", year: "numeric", month: "short", day: "numeric"},
      {hour: "2-digit", minute: "2-digit"},
      {hour: "numeric", minute: "2-digit", second: "2-digit", hour12: true},
      {hour: "numeric", minute: "2-digit", second: "2-digit", hour12: false}
    ]

    test_dates.each do |date_value|
      locales.each do |locale|
        styles.each_with_index do |options, style_index|
          # Generate unique ID
          date_id = date_value.gsub(/[:-]/, "").tr("T", "_").delete("Z")
          id = "datetime_#{locale.tr("-", "_")}_#{date_id}_style#{style_index}"

          @datetime_test_cases << {
            id:,
            value: date_value,
            locale:,
            options:
          }
        end
      end
    end
  end

  private def execute_node_comparator(input_data)
    input_json = JSON.generate(input_data)

    stdout, stderr, status = Open3.capture3("node", COMPARATOR_SCRIPT.to_s, stdin_data: input_json)

    unless status.success?
      warn "Node.js comparator failed: #{stderr}"
      return nil
    end

    JSON.parse(stdout)
  rescue JSON::ParserError => e
    warn "Failed to parse Node.js output: #{e.message}"
    nil
  end

  private def compare_number_results(test_cases, node_results)
    results_by_id = node_results.to_h {|r| [r["id"], r] }

    test_cases.map do |test_case|
      node_result = results_by_id[test_case[:id]]

      if node_result.nil?
        TestResult.new(
          id: test_case[:id],
          value: test_case[:value],
          locale: test_case[:locale],
          options: test_case[:options],
          foxtail_result: nil,
          node_result: nil,
          status: :error,
          error: "Node.js result not found"
        )
      elsif node_result["error"]
        TestResult.new(
          id: test_case[:id],
          value: test_case[:value],
          locale: test_case[:locale],
          options: test_case[:options],
          foxtail_result: nil,
          node_result: nil,
          status: :error,
          error: "Node.js error: #{node_result["error"]}"
        )
      else
        foxtail_result = format_number_with_foxtail(test_case[:value], test_case[:locale], test_case[:options])

        status = if foxtail_result == node_result["result"]
                   :match
                 elsif normalize_whitespace(foxtail_result) == normalize_whitespace(node_result["result"])
                   :conditional_match
                 else
                   :mismatch
                 end

        TestResult.new(
          id: test_case[:id],
          value: test_case[:value],
          locale: test_case[:locale],
          options: test_case[:options],
          foxtail_result:,
          node_result: node_result["result"],
          status:,
          error: nil
        )
      end
    end
  end

  private def compare_datetime_results(test_cases, node_results)
    results_by_id = node_results.to_h {|r| [r["id"], r] }

    test_cases.map do |test_case|
      node_result = results_by_id[test_case[:id]]

      if node_result.nil?
        TestResult.new(
          id: test_case[:id],
          value: test_case[:value],
          locale: test_case[:locale],
          options: test_case[:options],
          foxtail_result: nil,
          node_result: nil,
          status: :error,
          error: "Node.js result not found"
        )
      elsif node_result["error"]
        TestResult.new(
          id: test_case[:id],
          value: test_case[:value],
          locale: test_case[:locale],
          options: test_case[:options],
          foxtail_result: nil,
          node_result: nil,
          status: :error,
          error: "Node.js error: #{node_result["error"]}"
        )
      else
        foxtail_result = format_datetime_with_foxtail(test_case[:value], test_case[:locale], test_case[:options])

        status = if foxtail_result == node_result["result"]
                   :match
                 elsif normalize_whitespace(foxtail_result) == normalize_whitespace(node_result["result"])
                   :conditional_match
                 else
                   :mismatch
                 end

        TestResult.new(
          id: test_case[:id],
          value: test_case[:value],
          locale: test_case[:locale],
          options: test_case[:options],
          foxtail_result:,
          node_result: node_result["result"],
          status:,
          error: nil
        )
      end
    end
  end

  private def format_number_with_foxtail(value, locale, options)
    formatter = Foxtail::CLDR::Formatter::Number.new
    locale_tag = Locale::Tag.parse(locale)

    formatter.call(value, locale: locale_tag, **options)
  rescue => e
    "ERROR: #{e.message}"
  end

  private def format_datetime_with_foxtail(value, locale, options)
    formatter = Foxtail::CLDR::Formatter::DateTime.new
    locale_tag = Locale::Tag.parse(locale)

    formatter.call(value, locale: locale_tag, **options)
  rescue => e
    "ERROR: #{e.message}"
  end

  # Normalize whitespace characters for comparison
  # Converts non-breaking spaces (U+00A0) to regular spaces (U+0020)
  private def normalize_whitespace(text)
    text&.tr("\u00A0", " ")
  end
end
