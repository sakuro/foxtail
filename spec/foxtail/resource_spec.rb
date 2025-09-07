# frozen_string_literal: true

require "spec_helper"
require "tempfile"
require_relative "../../lib/foxtail/resource"

RSpec.describe Foxtail::Resource do
  describe ".from_string" do
    let(:ftl_source) do
      <<~FTL
        hello = Hello, {$name}!
        -brand = Firefox
        goodbye = Goodbye world
      FTL
    end

    it "parses FTL source into a Resource" do
      resource = Foxtail::Resource.from_string(ftl_source)

      expect(resource).to be_a(Foxtail::Resource)
      expect(resource.entries).to be_an(Array)
      expect(resource.entries.size).to eq(3)
      expect(resource.errors).to be_an(Array)
    end

    it "creates proper message entries" do
      resource = Foxtail::Resource.from_string(ftl_source)

      hello_msg = resource.entries[0]
      expect(hello_msg["type"]).to eq("message")
      expect(hello_msg["id"]).to eq("hello")
      expect(hello_msg["value"]).to be_an(Array)

      goodbye_msg = resource.entries[2]
      expect(goodbye_msg["type"]).to eq("message")
      expect(goodbye_msg["id"]).to eq("goodbye")
      expect(goodbye_msg["value"]).to eq("Goodbye world")
    end

    it "creates proper term entries" do
      resource = Foxtail::Resource.from_string(ftl_source)

      brand_term = resource.entries[1]
      expect(brand_term["type"]).to eq("term")
      expect(brand_term["id"]).to eq("-brand")
      expect(brand_term["value"]).to eq("Firefox")
    end

    it "accepts converter options" do
      resource = Foxtail::Resource.from_string(ftl_source, skip_junk: false, strict: true)
      expect(resource.entries.size).to eq(3)
    end
  end

  describe ".from_file" do
    let(:temp_file) { Tempfile.new(["test", ".ftl"]) }
    let(:ftl_content) { "test = Test message" }

    before do
      temp_file.write(ftl_content)
      temp_file.rewind
    end

    after do
      temp_file.close
      temp_file.unlink
    end

    it "reads and parses FTL file" do
      resource = Foxtail::Resource.from_file(temp_file.path)

      expect(resource.entries.size).to eq(1)
      expect(resource.entries.first["id"]).to eq("test")
      expect(resource.entries.first["value"]).to eq("Test message")
    end

    it "handles file encoding properly" do
      temp_file.write("hello = Hello world")
      temp_file.close

      resource = Foxtail::Resource.from_file(temp_file.path)
      expect(resource.entries.size).to eq(1)
    end
  end

  describe "instance methods" do
    let(:ftl_source) do
      <<~FTL
        hello = Hello world
        -brand = Firefox
        goodbye = Goodbye world
        -company = Mozilla
      FTL
    end

    let(:resource) { Foxtail::Resource.from_string(ftl_source) }

    describe "#empty?" do
      it "returns false when resource has entries" do
        expect(resource.empty?).to be false
      end

      it "returns true when resource is empty" do
        empty_resource = Foxtail::Resource.from_string("")
        expect(empty_resource.empty?).to be true
      end
    end

    describe "#size" do
      it "returns the number of entries" do
        expect(resource.size).to eq(4)
      end
    end

    describe "#each" do
      it "iterates over all entries" do
        expect {|b| resource.each(&b) }.to yield_control.exactly(4).times
      end
    end

    describe "Enumerable" do
      it "includes Enumerable and provides map functionality" do
        yielded_ids = resource.map {|entry| entry["id"] }
        expect(yielded_ids).to eq(["hello", "-brand", "goodbye", "-company"])
      end
    end

    describe "#messages" do
      it "returns only message entries" do
        messages = resource.messages
        expect(messages.size).to eq(2)
        expect(messages.map {|m| m["id"] }).to eq(%w[hello goodbye])
        expect(messages.all? {|m| m["type"] == "message" }).to be true
      end
    end

    describe "#terms" do
      it "returns only term entries" do
        terms = resource.terms
        expect(terms.size).to eq(2)
        expect(terms.map {|t| t["id"] }).to eq(["-brand", "-company"])
        expect(terms.all? {|t| t["type"] == "term" }).to be true
      end
    end

    describe "#find" do
      it "finds entry by ID" do
        entry = resource.find("hello")
        expect(entry["type"]).to eq("message")
        expect(entry["id"]).to eq("hello")
      end

      it "finds term entry by ID" do
        entry = resource.find("-brand")
        expect(entry["type"]).to eq("term")
        expect(entry["id"]).to eq("-brand")
      end

      it "returns nil when entry not found" do
        entry = resource.find("nonexistent")
        expect(entry).to be_nil
      end
    end
  end

  describe "error handling" do
    it "collects errors from converter" do
      # This would test error handling when we have actual error scenarios
      resource = Foxtail::Resource.from_string("valid = Valid message")
      expect(resource.errors).to be_an(Array)
    end
  end
end
