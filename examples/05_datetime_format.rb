# frozen_string_literal: true

# Example 05: Date/Time Formatting
#
# This example demonstrates:
# - Implicit DATETIME formatting for Time variables
# - Explicit DATETIME function for date/time style options
# - Locale-aware formatting

require "fantail"

# English (US)
en_bundle = Fantail::Bundle.new(ICU4X::Locale.parse("en-US"), use_isolating: false)
en_resource = Fantail::Resource.from_string(<<~FTL)
  # Implicit DATETIME formatting (automatically applied to Time variables)
  date-implicit = { $date }
  # Date only - various styles (requires explicit DATETIME with options)
  date-full = { DATETIME($date, dateStyle: "full") }
  date-long = { DATETIME($date, dateStyle: "long") }
  date-medium = { DATETIME($date, dateStyle: "medium") }
  date-short = { DATETIME($date, dateStyle: "short") }
  # Time only (requires explicit DATETIME with options)
  time-full = { DATETIME($time, timeStyle: "full") }
  time-short = { DATETIME($time, timeStyle: "short") }
  # Combined (requires explicit DATETIME with options)
  datetime = { DATETIME($dt, dateStyle: "medium", timeStyle: "short") }
FTL
en_bundle.add_resource(en_resource)

# Japanese
ja_bundle = Fantail::Bundle.new(ICU4X::Locale.parse("ja"), use_isolating: false)
ja_resource = Fantail::Resource.from_string(<<~FTL)
  # Implicit DATETIME formatting
  date-implicit = { $date }
  date-full = { DATETIME($date, dateStyle: "full") }
  date-medium = { DATETIME($date, dateStyle: "medium") }
  datetime = { DATETIME($dt, dateStyle: "medium", timeStyle: "short") }
FTL
ja_bundle.add_resource(ja_resource)

# Sample date/time
sample_date = Time.new(2025, 1, 4, 14, 30, 0, "+09:00")

puts "=== English (US) ==="
puts "Implicit: #{en_bundle.format("date-implicit", date: sample_date)}"
puts "Full:     #{en_bundle.format("date-full", date: sample_date)}"
puts "Long:     #{en_bundle.format("date-long", date: sample_date)}"
puts "Medium:   #{en_bundle.format("date-medium", date: sample_date)}"
puts "Short:    #{en_bundle.format("date-short", date: sample_date)}"
puts
puts "Time (full):  #{en_bundle.format("time-full", time: sample_date)}"
puts "Time (short): #{en_bundle.format("time-short", time: sample_date)}"
puts
puts "Combined: #{en_bundle.format("datetime", dt: sample_date)}"

puts "\n=== Japanese ==="
puts "Implicit: #{ja_bundle.format("date-implicit", date: sample_date)}"
puts "Full:     #{ja_bundle.format("date-full", date: sample_date)}"
puts "Medium:   #{ja_bundle.format("date-medium", date: sample_date)}"
puts "Combined: #{ja_bundle.format("datetime", dt: sample_date)}"
