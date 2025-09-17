#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "lib/foxtail"

puts "=== GitHub Actions Environment Debug ==="
puts "Ruby version: #{RUBY_VERSION}"
puts "Platform: #{RUBY_PLATFORM}"
puts "TZ environment variable: #{ENV["TZ"] || "not set"}"
puts "System timezone: #{Time.now.zone}"
puts "UTC offset: #{Time.now.utc_offset / 3600} hours"
puts "Current time: #{Time.now}"
puts "Current UTC time: #{Time.now.utc}"
puts

# Test the specific problematic case
formatter = Foxtail::CLDR::Formatter::DateTime.new
locale_tag = Locale::Tag.parse("fr-FR")

puts "=== Testing French Locale Timezone Formatting ==="

test_cases = [
  {
    value: "2023-02-14T23:59:59Z",
    options: {timeStyle: "long"},
    description: "timeStyle: long (no timezone specified)"
  },
  {
    value: "2023-02-14T23:59:59Z",
    options: {timeStyle: "short"},
    description: "timeStyle: short (no timezone specified)"
  },
  {
    value: "2023-02-14T23:59:59Z",
    options: {timeStyle: "long", timeZone: "UTC"},
    description: "timeStyle: long, explicit UTC"
  },
  {
    value: "2023-02-14T23:59:59Z",
    options: {timeStyle: "long", timeZone: "Etc/UTC"},
    description: "timeStyle: long, explicit Etc/UTC"
  }
]

test_cases.each do |test_case|
  puts "Testing: #{test_case[:description]}"
  puts "Options: #{test_case[:options].inspect}"

  begin
    result = formatter.call(test_case[:value], locale: locale_tag, **test_case[:options])
    puts "Result: '#{result}'"

    # Analyze characters
    hex_dump = result.unpack("U*").map {|code| "U+#{code.to_s(16).upcase.rjust(4, "0")}" }.join(" ")
    puts "Hex: #{hex_dump}"

    if result.include?("TU")
      puts "🚨 FOUND PROBLEM: 'TU' detected!"
    elsif result.include?("UTC")
      puts "✓ UTC found (expected)"
    else
      puts "? No UTC/TU found"
    end
  rescue => e
    puts "ERROR: #{e.message}"
    puts "Backtrace: #{e.backtrace.first(3).join(", ")}"
  end

  puts "---"
end

puts
puts "=== System Timezone Detection Debug ==="

# Debug timezone detection
begin
  # Access internal timezone detection if possible
  datetime_formatter = Foxtail::CLDR::Formatter::DateTime.new
  context = begin
    datetime_formatter.instance_variable_get(:@context)
  rescue
    nil
  end

  if context
    puts "Formatter context timezone info:"
    puts "Context class: #{context.class}"
    # Try to access system timezone method if available
    if context.respond_to?(:system_timezone, true)
      system_tz = begin
        context.__send__(:system_timezone)
      rescue
        "Failed to get system timezone"
      end
      puts "System timezone from context: #{system_tz}"
    end
  end
rescue => e
  puts "Could not access internal timezone info: #{e.message}"
end

puts
puts "=== Environment Variables ==="
ENV.each do |key, value|
  if key.match?(/time|zone|utc/i) || key.match?(/tz/i)
    puts "#{key}: #{value}"
  end
end
