# frozen_string_literal: true

require "icu4x"

RSpec.describe Fantail::Function do
  describe ".defaults" do
    it "returns callable ICU4X-based functions" do
      result = Fantail::Function.defaults

      expect(result.keys).to contain_exactly("NUMBER", "DATETIME")
      expect(result["NUMBER"]).to respond_to(:call)
      expect(result["DATETIME"]).to respond_to(:call)
    end

    it "returns correct formatted results" do
      result = Fantail::Function.defaults
      en_locale = ICU4X::Locale.parse("en")

      expect(result["NUMBER"].call(42, locale: en_locale)).to eq("42")
      # ICU4X requires dateStyle or timeStyle; use mid-year date to avoid timezone edge cases
      expect(result["DATETIME"].call(Time.new(2023, 6, 15), locale: en_locale, dateStyle: :medium)).to include("2023")
    end
  end
end
