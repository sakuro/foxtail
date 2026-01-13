# frozen_string_literal: true

# Dungeon Game Example
#
# This example demonstrates:
# - Two-layer bundle architecture (Items Bundle + Messages Bundle)
# - Custom functions (ITEM, ITEM_WITH_COUNT) for dynamic item localization
# - Locale-aware number formatting using ICU4X (1,000 vs 1.000 vs 1 000)
# - German grammatical cases (nominative, accusative, dative, genitive)
# - German grammatical gender (masculine, feminine, neuter)
# - French elision (l'épée vs la hache)
# - Proper article declension based on gender, number, and case

require "foxtail"
require "icu4x"
require "pathname"

require_relative "functions/base"
require_relative "functions/de"
require_relative "functions/en"
require_relative "functions/fr"
require_relative "functions/ja"

TARGET_LANGUAGES = %w[en de fr ja].freeze
TARGET_LOCALES = TARGET_LANGUAGES.to_h {|lang| [lang, ICU4X::Locale.parse(lang)] }.freeze

# Language class registry for item localization
module ItemFunctions
  LANGUAGE_CLASSES = {
    "de" => De,
    "en" => En,
    "fr" => Fr,
    "ja" => Ja
  }.freeze
  private_constant :LANGUAGE_CLASSES

  # Create language-specific custom functions
  # @param locale [ICU4X::Locale] The locale
  # @param items_bundle [Foxtail::Bundle] The bundle containing item terms
  # @return [Hash{String => #call}] Custom functions for the locale
  def self.functions_for_locale(locale, items_bundle)
    klass = LANGUAGE_CLASSES.fetch(locale.to_s, Base)
    klass.new(items_bundle).functions
  end
end

# Create a messages bundle for the specified locale
# @param locale [ICU4X::Locale] The locale
# @param locales_dir [Pathname] Directory containing locale subdirectories
# @return [Foxtail::Bundle] Configured messages bundle with custom functions
def create_bundle(locale, locales_dir)
  locale_dir = locales_dir.join(locale.to_s)

  # Items bundle loads: articles, counters, items
  items_bundle = Foxtail::Bundle.new(locale, use_isolating: false)
  %w[articles counters items].each do |name|
    path = locale_dir.join("#{name}.ftl")
    items_bundle.add_resource(Foxtail::Resource.from_file(path)) if path.exist?
  end

  # Messages bundle loads: messages
  messages_bundle = Foxtail::Bundle.new(locale, functions: ItemFunctions.functions_for_locale(locale, items_bundle), use_isolating: false)
  messages_bundle.add_resource(
    Foxtail::Resource.from_file(locale_dir.join("messages.ftl"))
  )

  messages_bundle
end

# Directory containing locale files
locales_dir = Pathname.new(__dir__).join("locales")

puts "=== Dungeon Game Localization Demo ==="
puts

# Test items (including counter items) - passed as term references with - prefix
items = %w[-dagger -axe -sword -hammer -herb -gold-coin -gauntlet -healing-potion -elixir]
counts = [1, 3, 1000]

# Language bundles
en = TARGET_LOCALES["en"]
dn = ICU4X::DisplayNames.new(en, type: :language)
bundles = TARGET_LOCALES.transform_values {|locale| create_bundle(locale, locales_dir) }

# Message IDs to test
message_ids = %w[found-item attack-with-item item-is-here drop-item inventory-item]

bundles.each do |lang, bundle|
  puts "--- #{dn.of(lang)} ---"
  message_ids.each do |message_id|
    puts "#{message_id}:"
    if message_id == "attack-with-item"
      puts "  #{bundle.format(message_id, item: "-sword")}"
    else
      items.each do |item|
        counts.each do |count|
          puts "  #{bundle.format(message_id, item:, count:)}"
        end
      end
    end
  end
  puts
end

# Demonstrate case differences in German
de_bundle = bundles["de"]
puts "=== German Grammatical Cases ==="
puts
puts "Nominative (subject): #{de_bundle.format("item-is-here", item: "-sword", count: 1)}"
puts "Accusative (direct object): #{de_bundle.format("found-item", item: "-sword", count: 1)}"
puts "Dative (with preposition): #{de_bundle.format("attack-with-item", item: "-sword")}"
puts

# Demonstrate gender differences in German
puts "=== German Grammatical Gender ==="
puts
puts "Masculine (der Dolch): #{de_bundle.format("found-item", item: "-dagger", count: 1)}"
puts "Feminine (die Axt): #{de_bundle.format("found-item", item: "-axe", count: 1)}"
puts "Neuter (das Schwert): #{de_bundle.format("found-item", item: "-sword", count: 1)}"
puts

# Demonstrate French elision
fr_bundle = bundles["fr"]
puts "=== French Elision ==="
puts
puts "With elision - vowel (l'épée): #{fr_bundle.format("item-is-here", item: "-sword", count: 1)}"
puts "With elision - h muet (l'herbe): #{fr_bundle.format("item-is-here", item: "-herb", count: 1)}"
puts "Without elision - h aspiré (la hache): #{fr_bundle.format("item-is-here", item: "-axe", count: 1)}"
puts "Without elision - consonant (le poignard): #{fr_bundle.format("item-is-here", item: "-dagger", count: 1)}"
puts
puts "=== French Counter Elision ==="
puts
puts "Counter + consonant (fiole de potion): #{fr_bundle.format("found-item", item: "-healing-potion", count: 1)}"
puts "Counter + vowel (fiole d'élixir): #{fr_bundle.format("found-item", item: "-elixir", count: 1)}"
