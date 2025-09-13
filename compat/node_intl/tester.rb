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

    # Basic decimal formatting
    add_decimal_tests

    # Currency formatting
    add_currency_tests

    # Percent formatting
    add_percent_tests

    # Scientific notation
    add_scientific_tests

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

  private def add_decimal_tests
    values = [0, 1, 12, 123, 1234, 12345, 123_456, 1_234_567, 1.5, 12.34, 123.456, -123.45]
    locales = %w[en-US ja-JP de-DE fr-FR]

    values.each do |value|
      locales.each do |locale|
        @test_cases << {
          id: "decimal_#{locale.tr("-", "_")}_#{value.to_s.gsub("-", "neg").tr(".", "_")}",
          value:,
          locale:,
          options: {style: "decimal"}
        }
      end
    end
  end

  private def add_currency_tests
    values = [0, 1, 12.34, 123.45, 1234.56, -123.45]
    test_cases = [
      {locale: "en-US", currency: "USD"},
      {locale: "ja-JP", currency: "JPY"},
      {locale: "de-DE", currency: "EUR"},
      {locale: "fr-FR", currency: "EUR"}
    ]

    values.each do |value|
      test_cases.each do |test_case|
        locale = test_case[:locale]
        currency = test_case[:currency]

        @test_cases << {
          id: "currency_#{locale.tr("-", "_")}_#{currency}_#{value.to_s.gsub("-", "neg").tr(".", "_")}",
          value:,
          locale:,
          options: {style: "currency", currency:}
        }
      end
    end
  end

  private def add_percent_tests
    values = [0, 0.1, 0.12, 0.123, 1, 1.23, -0.45]
    locales = %w[en-US ja-JP de-DE fr-FR]

    values.each do |value|
      locales.each do |locale|
        @test_cases << {
          id: "percent_#{locale.tr("-", "_")}_#{value.to_s.gsub("-", "neg").tr(".", "_")}",
          value:,
          locale:,
          options: {style: "percent"}
        }
      end
    end
  end

  private def add_scientific_tests
    values = [0, 1, 123, 0.000001, 123_456_789, 1.23e-10, 1.23e10]
    locales = %w[en-US ja-JP]

    values.each do |value|
      locales.each do |locale|
        @test_cases << {
          id: "scientific_#{locale.tr("-", "_")}_#{value.to_s.gsub("-", "neg").tr(".", "_").gsub("+", "pos")}",
          value:,
          locale:,
          options: {notation: "scientific"}
        }
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
