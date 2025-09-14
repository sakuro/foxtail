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
      status == :match
    end

    def failure?
      status == :mismatch || status == :error
    end
  }

  def initialize
    @test_cases = []
  end

  # Generate comprehensive test cases
  def generate_test_cases
    @test_cases = []

    # All style/notation combinations
    add_style_notation_combination_tests

    @test_cases
  end

  # Run all generated test cases
  def test_all
    generate_test_cases
    run_tests(@test_cases)
  end

  # Run Node.js comparisons for test cases
  def run_tests(test_cases)
    # Prepare input for Node.js script
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
    compare_results(test_cases, node_results)
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
    styles = ["decimal", "currency", "percent", "unit"]

    # All valid notation values
    notations = ["standard", "scientific", "engineering", "compact"]

    # Test locales
    locales = ["en-US", "ja-JP"]

    styles.each do |style|
      notations.each do |notation|
        test_values.each do |value|
          locales.each do |locale|
            # Build options based on style
            options = {style:, notation:}

            # Add required parameters for specific styles
            case style
            when "currency"
              options[:currency] = locale == "ja-JP" ? "JPY" : "USD"
            when "unit"
              options[:unit] = "kilometer"
              options[:unitDisplay] = "short"
            end

            # Generate unique ID
            id_parts = [style, notation, locale.tr("-", "_"), value.to_s.gsub("-", "neg").tr(".", "_")]
            id = id_parts.join("_")

            @test_cases << {
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

  private def compare_results(test_cases, node_results)
    results_by_id = (node_results["results"] || []).to_h {|r| [r["id"], r] }

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
        foxtail_result = format_with_foxtail(test_case[:value], test_case[:locale], test_case[:options])

        status = if foxtail_result == node_result["result"]
                   :match
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

  private def format_with_foxtail(value, locale, options)
    formatter = Foxtail::CLDR::Formatter::Number.new
    locale_tag = Locale::Tag.parse(locale)

    formatter.call(value, locale: locale_tag, **options)
  rescue => e
    "ERROR: #{e.message}"
  end
end
