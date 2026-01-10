# frozen_string_literal: true

RSpec.describe Foxtail::ICU4XCache do
  let(:cache) { Foxtail::ICU4XCache.instance }
  let(:locale) { ICU4X::Locale.parse("en") }

  describe "#number_formatter" do
    it "returns a NumberFormat instance" do
      formatter = cache.number_formatter(locale)

      expect(formatter).to be_a(ICU4X::NumberFormat)
    end

    it "returns the same instance for the same locale and options" do
      formatter1 = cache.number_formatter(locale)
      formatter2 = cache.number_formatter(locale)

      expect(formatter1).to be(formatter2)
    end

    it "returns different instances for different options" do
      formatter1 = cache.number_formatter(locale)
      formatter2 = cache.number_formatter(locale, style: :percent)

      expect(formatter1).not_to be(formatter2)
    end

    it "formats numbers correctly" do
      formatter = cache.number_formatter(locale)

      expect(formatter.format(1234)).to eq("1,234")
    end
  end

  describe "#datetime_formatter" do
    it "returns a DateTimeFormat instance" do
      formatter = cache.datetime_formatter(locale, date_style: :medium)

      expect(formatter).to be_a(ICU4X::DateTimeFormat)
    end

    it "returns the same instance for the same locale and options" do
      formatter1 = cache.datetime_formatter(locale, date_style: :medium)
      formatter2 = cache.datetime_formatter(locale, date_style: :medium)

      expect(formatter1).to be(formatter2)
    end

    it "returns different instances for different options" do
      formatter1 = cache.datetime_formatter(locale, date_style: :short)
      formatter2 = cache.datetime_formatter(locale, date_style: :long)

      expect(formatter1).not_to be(formatter2)
    end
  end

  describe "#plural_rules" do
    it "returns a PluralRules instance" do
      rules = cache.plural_rules(locale)

      expect(rules).to be_a(ICU4X::PluralRules)
    end

    it "returns the same instance for the same locale and type" do
      rules1 = cache.plural_rules(locale)
      rules2 = cache.plural_rules(locale)

      expect(rules1).to be(rules2)
    end

    it "returns different instances for different types" do
      rules1 = cache.plural_rules(locale, type: :cardinal)
      rules2 = cache.plural_rules(locale, type: :ordinal)

      expect(rules1).not_to be(rules2)
    end

    it "returns correct plural categories" do
      rules = cache.plural_rules(locale)

      expect(rules.select(1)).to eq(:one)
      expect(rules.select(2)).to eq(:other)
    end
  end
end
