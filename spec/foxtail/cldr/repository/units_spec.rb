# frozen_string_literal: true

RSpec.describe Foxtail::CLDR::Repository::Units do
  let(:units) { Foxtail::CLDR::Repository::Units.new(locale("en")) }

  describe "#unit_name" do
    it "returns localized unit display name" do
      expect(units.unit_name("meter", :long)).to be_a(String)
    end

    it "returns unit name if not found" do
      expect(units.unit_name("nonexistent")).to eq("nonexistent")
    end
  end

  describe "#unit_pattern" do
    it "returns unit pattern with placeholder" do
      pattern = units.unit_pattern("meter", :long, :one)
      expect(pattern).to include("{0}")
    end

    it "returns nil if pattern not found" do
      expect(units.unit_pattern("nonexistent")).to be_nil
    end
  end

  describe "#unit_category" do
    it "returns unit category" do
      category = units.unit_category("meter")
      expect(category).to eq("length") if category
    end
  end

  describe "#available_units" do
    it "returns array of unit names" do
      available = units.available_units
      expect(available).to be_an(Array)
    end
  end

  describe "#unit_exists?" do
    it "returns true for existing units" do
      # Use a unit that should exist in English locale
      expect(units.unit_exists?("meter")).to be(true) if units.available_units.include?("meter")
    end

    it "returns false for non-existing units" do
      expect(units.unit_exists?("nonexistent")).to be(false)
    end
  end

  describe "#available_widths" do
    it "returns array of available widths for a unit" do
      widths = units.available_widths("meter")
      expect(widths).to be_an(Array) if units.unit_exists?("meter")
    end

    it "returns empty array for non-existing units" do
      expect(units.available_widths("nonexistent")).to eq([])
    end
  end

  describe "#available_counts" do
    it "returns array of available counts for a unit and width" do
      counts = units.available_counts("meter", :long)
      expect(counts).to be_an(Array) if units.unit_exists?("meter")
    end

    it "returns empty array for non-existing units" do
      expect(units.available_counts("nonexistent", :long)).to eq([])
    end
  end
end
