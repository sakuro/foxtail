# frozen_string_literal: true

# Multilingual App Example
#
# This example demonstrates:
# - Loading FTL files from disk
# - Using Sequence for language fallback
# - Handling locale-specific messages

require "foxtail"
require "icu4x"
require "pathname"

# Directory containing locale files
locales_dir = Pathname.new(__dir__).join("locales")

# Load bundles for available locales
en_bundle = Foxtail::Bundle.new(ICU4X::Locale.parse("en"))
en_bundle.add_resource(Foxtail::Resource.from_file(locales_dir.join("en.ftl")))

ja_bundle = Foxtail::Bundle.new(ICU4X::Locale.parse("ja"))
ja_bundle.add_resource(Foxtail::Resource.from_file(locales_dir.join("ja.ftl")))

puts "=== Using Sequence for Fallback ==="
puts

# Create sequence with Japanese as primary, English as fallback
puts "--- Japanese primary (with English fallback) ---"
ja_sequence = Foxtail::Sequence.new(ja_bundle, en_bundle)

puts ja_sequence.format("hello", name: "太郎")
# => こんにちは、太郎さん！

puts ja_sequence.format("notifications", count: 3)
# => 3件の通知があります。

# Message only in English - falls back
puts ja_sequence.format("english-only")
# => This message is only available in English.

puts

# Create sequence with English as primary, Japanese as fallback
puts "--- English primary (with Japanese fallback) ---"
en_sequence = Foxtail::Sequence.new(en_bundle, ja_bundle)

puts en_sequence.format("hello", name: "Alice")
# => Hello, Alice!

puts en_sequence.format("notifications", count: 1)
# => You have one notification.

# Message only in Japanese - falls back
puts en_sequence.format("japanese-only")
# => このメッセージは日本語のみです。

puts
puts "=== Finding Which Bundle Has a Message ==="
puts

# Use find to determine which bundle contains a message
bundle = ja_sequence.find("english-only")
puts "Found 'english-only' in locale: #{bundle.locale}" if bundle

bundle = ja_sequence.find("japanese-only")
puts "Found 'japanese-only' in locale: #{bundle.locale}" if bundle

puts
puts "=== Menu Localization ==="
puts

puts "English:"
%w[menu-file menu-edit menu-view menu-help].each do |id|
  puts "  #{en_sequence.format(id)}"
end

puts
puts "Japanese:"
%w[menu-file menu-edit menu-view menu-help].each do |id|
  puts "  #{ja_sequence.format(id)}"
end
