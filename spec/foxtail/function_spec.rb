# frozen_string_literal: true

RSpec.describe Foxtail::Function do
  describe ".defaults" do
    it "returns ICU4X-based function Methods" do
      result = Foxtail::Function.defaults

      expect(result.keys).to contain_exactly("NUMBER", "DATETIME")
      expect(result["NUMBER"]).to be_a(Method)
      expect(result["DATETIME"]).to be_a(Method)
    end

    it "returns correct formatted results" do
      result = Foxtail::Function.defaults
      en_locale = locale("en")

      expect(result["NUMBER"].call(42, locale: en_locale)).to eq("42")
      # ICU4X requires dateStyle or timeStyle; use mid-year date to avoid timezone edge cases
      expect(result["DATETIME"].call(Time.new(2023, 6, 15), locale: en_locale, dateStyle: :medium)).to include("2023")
    end
  end
end
