# frozen_string_literal: true

require "time"

RSpec.describe Foxtail::Function do
  describe ".backend" do
    it "returns a backend symbol" do
      expect(Foxtail::Function.backend).to be_a(Symbol)
      expect(%i[javascript foxtail_intl]).to include(Foxtail::Function.backend)
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

    it "raises error for invalid backend" do
      expect {
        Foxtail::Function.backend = :unknown
      }.to raise_error(ArgumentError, "Backend must be :javascript or :foxtail_intl")
    end
  end

  describe ".configure" do
    after do
      # Reset configuration
      Foxtail::Function.instance_variable_set(:@backend, nil)
    end

    it "configures JavaScript backend" do
      Foxtail::Function.configure(backend_name: :javascript)
      expect(Foxtail::Function.backend).to eq(:javascript)
    end

    it "configures FoxtailIntl backend" do
      Foxtail::Function.configure(backend_name: :foxtail_intl)
      expect(Foxtail::Function.backend).to eq(:foxtail_intl)
    end

    it "auto-detects backend when :auto is specified" do
      Foxtail::Function.configure(backend_name: :auto)
      expect(%i[javascript foxtail_intl]).to include(Foxtail::Function.backend)
    end

    it "uses auto-detect by default" do
      Foxtail::Function.configure
      expect(%i[javascript foxtail_intl]).to include(Foxtail::Function.backend)
    end

    it "raises error for unknown backend" do
      expect {
        Foxtail::Function.configure(backend_name: :unknown)
      }.to raise_error(ArgumentError, "Backend must be :javascript or :foxtail_intl")
    end
  end

  describe ".backend_info" do
    it "returns backend information" do
      info = Foxtail::Function.backend_info
      expect(info).to have_key(:name)
      expect(info).to have_key(:available)
      expect(info).to have_key(:supported_functions)
      expect(info[:available]).to be true
      expect(info[:supported_functions]).to include("NUMBER", "DATETIME")
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
    it "returns function Procs that are callable" do
      result = Foxtail::Function.defaults

      # Should contain the expected keys
      expect(result.keys).to contain_exactly("NUMBER", "DATETIME")

      # Functions should be callable with signature (value, locale:, **options)
      en_locale = locale("en")

      # Skip if backend is not available (for JavaScript)
      if Foxtail::Function.backend == :javascript
        test_formatter = Foxtail::Function::JavaScript::NumberFormat.new(locale: en_locale)
        skip "JavaScript runtime not available" unless test_formatter.available?
      end

      expect(result["NUMBER"].call(42, locale: en_locale)).to eq("42")
      expect(result["DATETIME"].call(Time.new(2023, 1, 1), locale: en_locale)).to include("2023")
    end

    it "returns Proc instances for functions" do
      result = Foxtail::Function.defaults

      expect(result["NUMBER"]).to be_a(Proc)
      expect(result["DATETIME"]).to be_a(Proc)
    end
  end
end
