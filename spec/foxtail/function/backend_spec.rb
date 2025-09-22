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
      }.to raise_error(ArgumentError, /must be a subclass/)
    end
  end
end
