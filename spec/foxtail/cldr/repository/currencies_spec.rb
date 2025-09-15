# frozen_string_literal: true

RSpec.describe Foxtail::CLDR::Repository::Currencies do
  let(:currencies) { Foxtail::CLDR::Repository::Currencies.new(locale("en")) }

  describe "#currency_name" do
    it "returns localized currency display name" do
      name = currencies.currency_name("USD")
      expect(name).to eq("US dollars") # Default is :other form
    end

    it "returns currency code if name not found" do
      name = currencies.currency_name("NONEXISTENT") # Use truly non-existent currency code
      expect(name).to eq("NONEXISTENT")
    end

    it "supports plural forms" do
      one_name = currencies.currency_name("USD", :one)
      other_name = currencies.currency_name("USD", :other)

      expect(one_name).to eq("US dollar")
      expect(other_name).to eq("US dollars")
    end
  end

  describe "#currency_symbol" do
    it "returns currency symbol" do
      symbol = currencies.currency_symbol("USD")
      expect(symbol).to eq("$")
    end

    it "returns currency code if symbol not found" do
      symbol = currencies.currency_symbol("NONEXISTENT") # Use truly non-existent currency code
      expect(symbol).to eq("NONEXISTENT")
    end
  end

  describe "#available_currencies" do
    it "returns array of currency codes" do
      codes = currencies.available_currencies
      expect(codes).to be_an(Array)
      expect(codes).to include("USD")
    end
  end

  describe "#currency_exists?" do
    it "returns true for existing currency" do
      expect(currencies.currency_exists?("USD")).to be true
    end

    it "returns false for non-existing currency" do
      expect(currencies.currency_exists?("NONEXISTENT")).to be false
    end
  end
end
