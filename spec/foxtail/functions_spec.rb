# frozen_string_literal: true

require "time"

RSpec.describe Foxtail::Functions do
  describe "[]" do
    it "provides access to NUMBER and DATETIME functions" do
      expect(Foxtail::Functions["NUMBER"]).not_to be_nil
      expect(Foxtail::Functions["DATETIME"]).not_to be_nil
    end

    it "returns callable functions" do
      expect(Foxtail::Functions["NUMBER"]).to respond_to(:call)
      expect(Foxtail::Functions["DATETIME"]).to respond_to(:call)
    end

    it "returns frozen function instances" do
      expect(Foxtail::Functions["NUMBER"]).to be_frozen
      expect(Foxtail::Functions["DATETIME"]).to be_frozen
    end
  end

  describe ".defaults" do
    it "returns function instances that are callable" do
      result = Foxtail::Functions.defaults

      # Should contain the expected keys
      expect(result.keys).to contain_exactly("NUMBER", "DATETIME")

      # Functions should be callable and produce same results
      en_locale = locale("en")
      expect(result["NUMBER"].call(42, {}, locale: en_locale)).to eq(Foxtail::Functions["NUMBER"].call(42, {}, locale: en_locale))
      expect(result["DATETIME"].call(Time.new(2023, 1, 1), {}, locale: en_locale)).to eq(Foxtail::Functions["DATETIME"].call(Time.new(2023, 1, 1), {}, locale: en_locale))
    end

    it "returns class instances instead of lambdas for better performance" do
      result = Foxtail::Functions.defaults

      expect(result["NUMBER"]).to be_a(Foxtail::Functions::NumberFormatter)
      expect(result["DATETIME"]).to be_a(Foxtail::Functions::DateTimeFormatter)
    end
  end
end
