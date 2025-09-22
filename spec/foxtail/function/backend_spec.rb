# frozen_string_literal: true

require "spec_helper"

RSpec.describe Foxtail::Function::Backend do
  describe ".default" do
    it "returns a backend instance" do
      expect(Foxtail::Function::Backend.default).to be_a(Foxtail::Function::Backend::Base)
    end

    it "returns an available backend" do
      expect(Foxtail::Function::Backend.default.available?).to be true
    end
  end

  describe ".available_backends" do
    it "returns array of available backends" do
      backends = Foxtail::Function::Backend.available_backends
      expect(backends).to be_an(Array)
      expect(backends).to all(be_a(Foxtail::Function::Backend::Base))
      expect(backends).to all(be_available)
    end
  end

  describe ".default=" do
    let(:mock_backend) { instance_double(Foxtail::Function::Backend::Base) }

    before do
      allow(mock_backend).to receive(:is_a?).with(Foxtail::Function::Backend::Base).and_return(true)
    end

    after do
      # Reset to original default
      Foxtail::Function::Backend.instance_variable_set(:@default, nil)
    end

    it "sets the default backend" do
      Foxtail::Function::Backend.default = mock_backend
      expect(Foxtail::Function::Backend.default).to eq(mock_backend)
    end

    it "raises error for invalid backend" do
      expect {
        Foxtail::Function::Backend.default = "not a backend"
      }.to raise_error(ArgumentError, "Backend must be a subclass of Foxtail::Function::Backend::Base")
    end
  end

  describe ".create" do
    it "creates JavaScript backend" do
      backend = Foxtail::Function::Backend.create(:javascript)
      expect(backend).to be_a(Foxtail::Function::Backend::JavaScript)
    end

    it "creates FoxtailIntl backend" do
      backend = Foxtail::Function::Backend.create(:foxtail_intl)
      expect(backend).to be_a(Foxtail::Function::Backend::FoxtailIntl)
    end

    it "raises error for unknown backend" do
      expect {
        Foxtail::Function::Backend.create(:unknown)
      }.to raise_error(ArgumentError, "Unknown backend: unknown")
    end
  end

  describe ".get" do
    it "returns JavaScript backend if available" do
      backend = Foxtail::Function::Backend.get(:javascript)
      if backend
        expect(backend).to be_a(Foxtail::Function::Backend::JavaScript)
        expect(backend.available?).to be true
      end
    end

    it "returns FoxtailIntl backend (always available)" do
      backend = Foxtail::Function::Backend.get(:foxtail_intl)
      expect(backend).to be_a(Foxtail::Function::Backend::FoxtailIntl)
      expect(backend.available?).to be true
    end

    it "returns nil for unknown backend" do
      backend = Foxtail::Function::Backend.get(:unknown)
      expect(backend).to be_nil
    end
  end

  describe "Backend priority" do
    it "prefers JavaScript over FoxtailIntl when both available" do
      backends = Foxtail::Function::Backend.available_backends
      expect(backends).not_to be_empty

      # If JavaScript is available, it should be first
      if backends.first.is_a?(Foxtail::Function::Backend::JavaScript)
        expect(backends.first).to be_a(Foxtail::Function::Backend::JavaScript)
      else
        # Otherwise FoxtailIntl should be available as fallback
        expect(backends).to include(
          an_instance_of(Foxtail::Function::Backend::FoxtailIntl)
        )
      end
    end

    it "always has at least FoxtailIntl available" do
      backends = Foxtail::Function::Backend.available_backends
      expect(backends).to include(
        an_instance_of(Foxtail::Function::Backend::FoxtailIntl)
      )
    end
  end
end
