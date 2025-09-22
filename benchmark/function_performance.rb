#!/usr/bin/env ruby
# frozen_string_literal: true

require "benchmark"
require "bundler/setup"
require_relative "../lib/foxtail"
require "execjs"
require "locale"
require "timeout"

# Benchmark script to compare JavaScript vs Foxtail::Intl performance
# Tests complex locales with different numbering systems and formatting rules
class FunctionPerformanceBenchmark
  def initialize
    @test_locales = [
      {tag: "ja-JP", name: "Japanese", numbering: "latn"},
      {tag: "ar-EG", name: "Arabic (Egypt)", numbering: "arab"},
      {tag: "hi-IN", name: "Hindi (India)", numbering: "deva"},
      {tag: "th-TH", name: "Thai", numbering: "thai"},
      {tag: "zh-CN", name: "Chinese (Simplified)", numbering: "hanidec"},
      {tag: "fa-IR", name: "Persian", numbering: "arabext"},
      {tag: "ru-RU", name: "Russian", numbering: "latn"},
      {tag: "de-DE", name: "German", numbering: "latn"}
    ]

    @test_numbers = [
      42,
      1234.56,
      123_456_789.123,
      0.00001,
      -999.99,
      1_000_000_000
    ]

    @test_dates = [
      Time.new(2023, 6, 15, 14, 30, 0),
      Time.new(2024, 12, 25, 9, 0, 0),
      Time.new(2020, 1, 1, 23, 59, 59)
    ]

    setup_formatters
  end

  def setup_formatters
    puts "Setting up formatters for complex locales..."
    puts "ExecJS runtime: #{execjs_available? ? ExecJS.runtime.name : "Not available"}"
    puts

    @formatters = {}

    @test_locales.each do |locale_info|
      tag = locale_info[:tag]
      locale = Locale::Tag.parse(tag)

      begin
        # JavaScript formatters
        js_basic = Foxtail::Function::JavaScript::NumberFormat.new(locale:)
        js_currency = Foxtail::Function::JavaScript::NumberFormat.new(
          locale:,
          style: "currency",
          currency: currency_for_locale(tag)
        )
        js_datetime = Foxtail::Function::JavaScript::DateTimeFormat.new(
          locale:, dateStyle: "full", timeStyle: "medium"
        )

        # Test if JavaScript is available for this locale
        if js_basic.available?
          js_basic.call(1234) # Test call
        end

        # Foxtail::Intl formatters
        intl_basic = Foxtail::Intl::NumberFormat.new(locale:)
        intl_currency = Foxtail::Intl::NumberFormat.new(
          locale:,
          style: "currency",
          currency: currency_for_locale(tag)
        )
        intl_datetime = Foxtail::Intl::DateTimeFormat.new(
          locale:, dateStyle: "full", timeStyle: "medium"
        )

        @formatters[tag] = {
          info: locale_info,
          locale:,
          js: {
            basic: js_basic,
            currency: js_currency,
            datetime: js_datetime
          },
          intl: {
            basic: intl_basic,
            currency: intl_currency,
            datetime: intl_datetime
          }
        }

        puts "✓ #{locale_info[:name]} (#{tag}) - JS: #{js_basic.available?}"
      rescue => e
        puts "✗ #{locale_info[:name]} (#{tag}) - Error: #{e.message}"
      end
    end
    puts
  end

  def currency_for_locale(tag)
    case tag
    when "ja-JP" then "JPY"
    when "ar-EG" then "EGP"
    when "hi-IN" then "INR"
    when "th-TH" then "THB"
    when "zh-CN" then "CNY"
    when "fa-IR" then "IRR"
    when "ru-RU" then "RUB"
    when "de-DE" then "EUR"
    else "USD"
    end
  end

  def run_with_timeout(timeout_seconds)
    Timeout.timeout(timeout_seconds) do
      yield
    end
  rescue Timeout::Error
    puts "TIMEOUT (#{timeout_seconds}s)"
  end

  def run_benchmarks
    iterations = 2000
    timeout_seconds = 30

    puts "=== Complex Locale Performance Comparison ==="
    puts "Iterations: #{iterations}"
    puts "Test numbers: #{@test_numbers.size}, Test dates: #{@test_dates.size}"
    puts "Timeout: #{timeout_seconds} seconds per test"
    puts

    @formatters.each do |tag, data|
      puts "--- #{data[:info][:name]} (#{tag}) ---"
      puts "Numbering system: #{data[:info][:numbering]}"

      # Skip if JavaScript not available
      unless data[:js][:basic].available?
        puts "JavaScript not available, skipping..."
        next
      end

      # Basic number formatting
      puts "\nBasic number formatting:"
      Benchmark.bm(15) do |x|
        x.report("JavaScript:") do
          run_with_timeout(timeout_seconds) do
            iterations.times do
              @test_numbers.each {|num| data[:js][:basic].call(num) }
            end
          end
        end

        x.report("Foxtail::Intl:") do
          run_with_timeout(timeout_seconds) do
            iterations.times do
              @test_numbers.each {|num| data[:intl][:basic].call(num) }
            end
          end
        end
      end

      # Currency formatting (more complex)
      puts "\nCurrency formatting:"
      Benchmark.bm(15) do |x|
        x.report("JavaScript:") do
          run_with_timeout(timeout_seconds) do
            iterations.times do
              @test_numbers.each {|num| data[:js][:currency].call(num) }
            end
          end
        end

        x.report("Foxtail::Intl:") do
          run_with_timeout(timeout_seconds) do
            iterations.times do
              @test_numbers.each {|num| data[:intl][:currency].call(num) }
            end
          end
        end
      end

      # DateTime formatting (complex locale-specific rules)
      puts "\nDateTime formatting:"
      Benchmark.bm(15) do |x|
        x.report("JavaScript:") do
          run_with_timeout(timeout_seconds) do
            iterations.times do
              @test_dates.each {|date| data[:js][:datetime].call(date) }
            end
          end
        end

        x.report("Foxtail::Intl:") do
          run_with_timeout(timeout_seconds) do
            iterations.times do
              @test_dates.each {|date| data[:intl][:datetime].call(date) }
            end
          end
        end
      end

      puts "\n#{"=" * 50}"
    end
  end

  def run_accuracy_check
    puts "=== Accuracy Verification (Complex Locales) ==="

    test_number = 1_234_567.89
    test_date = Time.new(2023, 6, 15, 14, 30, 0)

    @formatters.each do |tag, data|
      next unless data[:js][:basic].available?

      puts "\n--- #{data[:info][:name]} (#{tag}) ---"

      # Number formatting
      js_num = data[:js][:basic].call(test_number)
      intl_num = data[:intl][:basic].call(test_number)
      puts "Number (#{test_number}):"
      puts "  JavaScript:    '#{js_num}'"
      puts "  Foxtail::Intl: '#{intl_num}'"
      puts "  Match: #{js_num == intl_num ? "✓" : "✗"}"

      # Currency formatting
      js_curr = data[:js][:currency].call(test_number)
      intl_curr = data[:intl][:currency].call(test_number)
      puts "Currency:"
      puts "  JavaScript:    '#{js_curr}'"
      puts "  Foxtail::Intl: '#{intl_curr}'"
      puts "  Match: #{js_curr == intl_curr ? "✓" : "✗"}"

      # DateTime formatting
      js_date = data[:js][:datetime].call(test_date)
      intl_date = data[:intl][:datetime].call(test_date)
      puts "DateTime (#{test_date}):"
      puts "  JavaScript:    '#{js_date}'"
      puts "  Foxtail::Intl: '#{intl_date}'"
      puts "  Match: #{js_date == intl_date ? "✓" : "✗"}"
    end
  end

  def execjs_available?
    ExecJS.runtime
    true
  rescue ExecJS::RuntimeUnavailable
    false
  end

  def show_numbering_system_examples
    puts "\n=== Numbering System Examples ==="
    puts "ExecJS runtime: #{execjs_available? ? ExecJS.runtime.name : "Not available"}"
    puts

    test_num = 123_456

    @formatters.each_value do |data|
      next unless data[:js][:basic].available?

      js_result = data[:js][:basic].call(test_num)
      intl_result = data[:intl][:basic].call(test_num)

      puts "#{data[:info][:name]} (#{data[:info][:numbering]}):"
      puts "  Input: #{test_num}"
      puts "  JavaScript:    '#{js_result}'"
      puts "  Foxtail::Intl: '#{intl_result}'"
      puts
    end
  end
end

# Run the benchmark
if __FILE__ == $0
  benchmark = FunctionPerformanceBenchmark.new
  benchmark.show_numbering_system_examples
  benchmark.run_accuracy_check
  benchmark.run_benchmarks
end
