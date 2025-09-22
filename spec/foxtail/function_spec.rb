# frozen_string_literal: true

require "time"

RSpec.describe Foxtail::Function do
  describe ".backend" do
    it "returns a backend instance" do
      expect(Foxtail::Function.backend).to be_a(Foxtail::Function::Backend::Base)
    end

    it "returns an available backend by default" do
      expect(Foxtail::Function.backend.available?).to be true
    end
  end

  describe ".backend=" do
    let(:mock_backend) { instance_double(Foxtail::Function::Backend::Base) }

    before do
      allow(mock_backend).to receive(:is_a?).with(Foxtail::Function::Backend::Base).and_return(true)
    end

    after do
      # Reset to default backend
      Foxtail::Function.instance_variable_set(:@backend, nil)
    end

    it "sets the backend" do
      Foxtail::Function.backend = mock_backend
      expect(Foxtail::Function.backend).to eq(mock_backend)
    end

    it "raises error for invalid backend" do
      expect {
        Foxtail::Function.backend = "not a backend"
      }.to raise_error(ArgumentError, "Backend must be a subclass of Foxtail::Function::Backend::Base")
    end
  end

  describe ".configure" do
    after do
      # Reset configuration
      Foxtail::Function.instance_variable_set(:@backend, nil)
    end

    it "configures JavaScript backend" do
      Foxtail::Function.configure(backend_name: :javascript)
      expect(Foxtail::Function.backend).to be_a(Foxtail::Function::Backend::JavaScript)
    end

    it "raises error for unknown backend" do
      expect {
        Foxtail::Function.configure(backend_name: :unknown)
      }.to raise_error(ArgumentError, "Unknown backend: unknown")
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

    it "returns Proc instances" do
      expect(Foxtail::Function["NUMBER"]).to be_a(Proc)
      expect(Foxtail::Function["DATETIME"]).to be_a(Proc)
    end
  end

  describe ".defaults" do
    it "returns function instances that are callable" do
      result = Foxtail::Function.defaults

      # Should contain the expected keys
      expect(result.keys).to contain_exactly("NUMBER", "DATETIME")

      # Functions should be callable with new signature (value, locale:, **options)
      # Skip if backend is not available
      skip "Backend not available" unless Foxtail::Function.backend.available?

      en_locale = locale("en")
      expect(result["NUMBER"].call(42, locale: en_locale)).to eq("42")
      expect(result["DATETIME"].call(Time.new(2023, 1, 1), locale: en_locale)).to include("2023")
    end

    it "returns Proc instances for lazy initialization" do
      result = Foxtail::Function.defaults

      expect(result["NUMBER"]).to be_a(Proc)
      expect(result["DATETIME"]).to be_a(Proc)
    end

    it "delegates to backend" do
      mock_backend = instance_double(Foxtail::Function::Backend::Base)
      allow(mock_backend).to receive(:is_a?).with(Foxtail::Function::Backend::Base).and_return(true)
      allow(mock_backend).to receive(:call).with("NUMBER", 42, locale: anything).and_return("formatted")

      original_backend = Foxtail::Function.backend
      Foxtail::Function.backend = mock_backend

      result = Foxtail::Function["NUMBER"].call(42, locale: locale("en"))
      expect(result).to eq("formatted")

      # Restore original backend
      Foxtail::Function.backend = original_backend
    end
  end
end
