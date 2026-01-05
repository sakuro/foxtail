# frozen_string_literal: true

# Example 05: Date/Time Formatting
#
# This example demonstrates:
# - DATETIME function for locale-aware formatting
# - Date styles (full, long, medium, short)
# - Time styles
# - Combined date and time

require "foxtail"

# English (US)
en_bundle = Foxtail::Bundle.new(ICU4X::Locale.parse("en-US"))
en_resource = Foxtail::Resource.from_string(<<~FTL)
  # Date only - various styles
  date-full = { DATETIME($date, dateStyle: "full") }
  date-long = { DATETIME($date, dateStyle: "long") }
  date-medium = { DATETIME($date, dateStyle: "medium") }
  date-short = { DATETIME($date, dateStyle: "short") }
  # Time only
  time-full = { DATETIME($time, timeStyle: "full") }
  time-short = { DATETIME($time, timeStyle: "short") }
  # Combined
  datetime = { DATETIME($dt, dateStyle: "medium", timeStyle: "short") }
FTL
en_bundle.add_resource(en_resource)

# Japanese
ja_bundle = Foxtail::Bundle.new(ICU4X::Locale.parse("ja"))
ja_resource = Foxtail::Resource.from_string(<<~FTL)
  date-full = { DATETIME($date, dateStyle: "full") }
  date-medium = { DATETIME($date, dateStyle: "medium") }
  datetime = { DATETIME($dt, dateStyle: "medium", timeStyle: "short") }
FTL
ja_bundle.add_resource(ja_resource)

# Sample date/time
sample_date = Time.new(2025, 1, 4, 14, 30, 0, "+09:00")

puts "=== English (US) ==="
puts "Full:   #{en_bundle.format("date-full", date: sample_date)}"
puts "Long:   #{en_bundle.format("date-long", date: sample_date)}"
puts "Medium: #{en_bundle.format("date-medium", date: sample_date)}"
puts "Short:  #{en_bundle.format("date-short", date: sample_date)}"
puts
puts "Time (full):  #{en_bundle.format("time-full", time: sample_date)}"
puts "Time (short): #{en_bundle.format("time-short", time: sample_date)}"
puts
puts "Combined: #{en_bundle.format("datetime", dt: sample_date)}"

puts "\n=== Japanese ==="
puts "Full:   #{ja_bundle.format("date-full", date: sample_date)}"
puts "Medium: #{ja_bundle.format("date-medium", date: sample_date)}"
puts "Combined: #{ja_bundle.format("datetime", dt: sample_date)}"
