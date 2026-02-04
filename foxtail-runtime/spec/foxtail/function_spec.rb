# frozen_string_literal: true

require "icu4x"

RSpec.describe Foxtail::Function do
  describe ".defaults" do
    it "returns callable ICU4X-based functions" do
      result = Foxtail::Function.defaults

      expect(result.keys).to contain_exactly("NUMBER", "DATETIME")
      expect(result["NUMBER"]).to respond_to(:call)
      expect(result["DATETIME"]).to respond_to(:call)
    end

    it "returns Value objects for deferred formatting" do
      result = Foxtail::Function.defaults
      bundle = Foxtail::Bundle.new(ICU4X::Locale.parse("en"))

      # NUMBER returns a Function::Number for deferred formatting
      number_value = result["NUMBER"].call(42)
      expect(number_value).to be_a(Foxtail::Function::Number)
      expect(number_value.value).to eq(42)
      expect(number_value.format(bundle:)).to eq("42")

      # DATETIME returns a Function::DateTime for deferred formatting
      datetime_value = result["DATETIME"].call(Time.new(2023, 6, 15), dateStyle: :medium)
      expect(datetime_value).to be_a(Foxtail::Function::DateTime)
      expect(datetime_value.format(bundle:)).to include("2023")
    end
  end
end
