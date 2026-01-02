# frozen_string_literal: true

require "time"

RSpec.describe Foxtail::Function do
  describe ".backend" do
    it "returns a backend symbol" do
      expect(Foxtail::Function.backend).to be_a(Symbol)
      expect(%i[icu4x javascript foxtail_intl]).to include(Foxtail::Function.backend)
    end
  end

  describe ".backend=" do
    after do
      # Reset to default backend
      Foxtail::Function.instance_variable_set(:@backend, nil)
    end

    it "sets the backend symbol" do
      Foxtail::Function.backend = :foxtail_intl
      expect(Foxtail::Function.backend).to eq(:foxtail_intl)
    end

    it "auto-detects backend when :auto is specified" do
      Foxtail::Function.backend = :auto
      expect(%i[icu4x javascript foxtail_intl]).to include(Foxtail::Function.backend)
    end

    it "raises error for invalid backend" do
      expect {
        Foxtail::Function.backend = :unknown
      }.to raise_error(ArgumentError, "Backend must be :auto, :icu4x, :javascript, or :foxtail_intl")
    end
  end

  describe "[]" do
    it "provides access to NUMBER and DATETIME functions" do
      expect(Foxtail::Function["NUMBER"]).not_to be_nil
      expect(Foxtail::Function["DATETIME"]).not_to be_nil
    end

    it "returns callable functions" do
      expect(Foxtail::Function["NUMBER"]).to respond_to(:call)
      expect(Foxtail::Function["DATETIME"]).to respond_to(:call)
    end
  end

  describe ".defaults" do
    context "with JavaScript backend" do
      around do |example|
        Foxtail::Function.backend = :javascript
        example.run
        Foxtail::Function.instance_variable_set(:@backend, nil)
      end

      it "returns JavaScript-based function Procs" do
        result = Foxtail::Function.defaults

        expect(result.keys).to contain_exactly("NUMBER", "DATETIME")
        expect(result["NUMBER"]).to be_a(Proc)
        expect(result["DATETIME"]).to be_a(Proc)
      end

      it "returns correct formatted results", :requires_javascript do
        result = Foxtail::Function.defaults
        en_locale = locale("en")

        expect(result["NUMBER"].call(42, locale: en_locale)).to eq("42")
        expect(result["DATETIME"].call(Time.new(2023, 1, 1), locale: en_locale)).to include("2023")
      end
    end

    context "with Foxtail::Intl backend" do
      around do |example|
        Foxtail::Function.backend = :foxtail_intl
        example.run
        Foxtail::Function.instance_variable_set(:@backend, nil)
      end

      it "returns Foxtail::Intl-based function Procs" do
        result = Foxtail::Function.defaults

        expect(result.keys).to contain_exactly("NUMBER", "DATETIME")
        expect(result["NUMBER"]).to be_a(Proc)
        expect(result["DATETIME"]).to be_a(Proc)
      end

      it "returns correct formatted results" do
        result = Foxtail::Function.defaults
        en_locale = locale("en")

        expect(result["NUMBER"].call(42, locale: en_locale)).to eq("42")
        expect(result["DATETIME"].call(Time.new(2023, 1, 1), locale: en_locale)).to include("2023")
      end
    end

    context "with ICU4X backend" do
      around do |example|
        Foxtail::Function.backend = :icu4x
        example.run
        Foxtail::Function.instance_variable_set(:@backend, nil)
      end

      it "returns ICU4X-based function Procs" do
        result = Foxtail::Function.defaults

        expect(result.keys).to contain_exactly("NUMBER", "DATETIME")
        expect(result["NUMBER"]).to be_a(Proc)
        expect(result["DATETIME"]).to be_a(Proc)
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
end
