# frozen_string_literal: true

require "json"
require "locale"
require "open3"
require "pathname"
require_relative "../../lib/foxtail"

# Executes Node.js Intl.NumberFormat compatibility tests
class NodeIntlTester
  # Path to Node.js comparator script
  COMPARATOR_SCRIPT = Pathname(__dir__) / "comparator.js"
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
      -987.65,     # Negative number
      "Infinity",  # Positive infinity (as string for JSON compatibility)
      "-Infinity", # Negative infinity (as string for JSON compatibility)
      "NaN"        # Not a Number (as string for JSON compatibility)
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
            # Handle special values in ID generation
            value_part = case value
                         when "Infinity"
                           "Infinity"
                         when "-Infinity"
                           "NegInfinity"
                         when "NaN"
                           "NaN"
                         else
                           value.to_s.gsub("-", "neg").tr(".", "_")
                         end
            id_parts = ["number", style, notation, locale.tr("-", "_"), value_part]
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
      "2024-02-29T12:00:00Z",     # Leap year date
      "Infinity",                 # Special value: positive infinity
      "-Infinity",                # Special value: negative infinity
      "NaN" # Special value: not a number
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
      {hour: "numeric", minute: "2-digit", second: "2-digit", hour12: false},
      # Timezone-specific test cases
      {timeStyle: "full", timeZone: "Asia/Tokyo"},
      {timeStyle: "long", timeZone: "Asia/Tokyo"},
      {timeStyle: "full", timeZone: "Europe/London"},
      {timeStyle: "long", timeZone: "Europe/London"},
      {timeStyle: "full", timeZone: "America/New_York"},
      {timeStyle: "long", timeZone: "America/New_York"}
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
        # Node.js threw an error - check if Foxtail also throws an error
        foxtail_response = format_number_with_foxtail(test_case[:value], test_case[:locale], test_case[:options])

        # Both should error for special values
        status = if foxtail_response[:error]
                   :match # Both threw errors - this is correct behavior
                 else
                   :mismatch # Node.js threw error, but Foxtail returned a value - inconsistent
                 end

        TestResult.new(
          id: test_case[:id],
          value: test_case[:value],
          locale: test_case[:locale],
          options: test_case[:options],
          foxtail_result: foxtail_response[:error] ? "ERROR: #{foxtail_response[:error]}" : foxtail_response[:result],
          node_result: "ERROR: #{node_result["error"]}",
          status:,
          error: nil
        )
      else
        foxtail_response = format_number_with_foxtail(test_case[:value], test_case[:locale], test_case[:options])

        # Node.js succeeded - check if Foxtail also succeeded
        if foxtail_response[:error]
          # Node.js succeeded but Foxtail errored - mismatch
          TestResult.new(
            id: test_case[:id],
            value: test_case[:value],
            locale: test_case[:locale],
            options: test_case[:options],
            foxtail_result: "ERROR: #{foxtail_response[:error]}",
            node_result: node_result["result"],
            status: :mismatch,
            error: nil
          )
        else
          # Both succeeded - compare the results
          status = determine_match_status(foxtail_response[:result], node_result["result"])

          TestResult.new(
            id: test_case[:id],
            value: test_case[:value],
            locale: test_case[:locale],
            options: test_case[:options],
            foxtail_result: foxtail_response[:result],
            node_result: node_result["result"],
            status:,
            error: nil
          )
        end
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
        # Node.js threw an error - check if Foxtail also throws an error
        foxtail_response = format_datetime_with_foxtail(test_case[:value], test_case[:locale], test_case[:options])

        # Both should error for special values
        status = if foxtail_response[:error]
                   :match # Both threw errors - this is correct behavior
                 else
                   :mismatch # Node.js threw error, but Foxtail returned a value - inconsistent
                 end

        TestResult.new(
          id: test_case[:id],
          value: test_case[:value],
          locale: test_case[:locale],
          options: test_case[:options],
          foxtail_result: foxtail_response[:error] ? "ERROR: #{foxtail_response[:error]}" : foxtail_response[:result],
          node_result: "ERROR: #{node_result["error"]}",
          status:,
          error: nil
        )
      else
        foxtail_response = format_datetime_with_foxtail(test_case[:value], test_case[:locale], test_case[:options])

        # Node.js succeeded - check if Foxtail also succeeded
        if foxtail_response[:error]
          # Node.js succeeded but Foxtail errored - mismatch
          TestResult.new(
            id: test_case[:id],
            value: test_case[:value],
            locale: test_case[:locale],
            options: test_case[:options],
            foxtail_result: "ERROR: #{foxtail_response[:error]}",
            node_result: node_result["result"],
            status: :mismatch,
            error: nil
          )
        else
          # Both succeeded - compare the results
          status = determine_match_status(foxtail_response[:result], node_result["result"])

          TestResult.new(
            id: test_case[:id],
            value: test_case[:value],
            locale: test_case[:locale],
            options: test_case[:options],
            foxtail_result: foxtail_response[:result],
            node_result: node_result["result"],
            status:,
            error: nil
          )
        end
      end
    end
  end

  private def format_number_with_foxtail(value, locale, options)
    # Convert special string values to actual Ruby constants
    actual_value = case value
                   when "Infinity"
                     Float::INFINITY
                   when "-Infinity"
                     -Float::INFINITY
                   when "NaN"
                     Float::NAN
                   else
                     value
                   end

    locale_tag = Locale::Tag.parse(locale)
    formatter = Foxtail::Intl::NumberFormat.new(locale: locale_tag, **options)

    result = formatter.call(actual_value)
    {result:, error: nil}
  rescue => e
    {result: nil, error: e.message}
  end

  private def format_datetime_with_foxtail(value, locale, options)
    locale_tag = Locale::Tag.parse(locale)
    formatter = Foxtail::Intl::DateTimeFormat.new(locale: locale_tag, **options)

    result = formatter.call(value)
    {result:, error: nil}
  rescue => e
    {result: nil, error: e.message}
  end

  # Determine match status between Foxtail and Node.js results
  private def determine_match_status(foxtail_result, node_result)
    # Exact match
    return :match if foxtail_result == node_result

    # Whitespace normalization (conditional match)
    return :conditional_match if normalize_whitespace(foxtail_result) == normalize_whitespace(node_result)

    # No match
    :mismatch
  end

  # Normalize whitespace characters for comparison
  # Converts various Unicode space characters to regular spaces (U+0020)
  # U+00A0: non-breaking space, U+202F: thin space
  private def normalize_whitespace(text)
    text&.tr("\u00A0\u202F", " ")
  end
end
