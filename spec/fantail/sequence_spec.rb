# frozen_string_literal: true

RSpec.describe Fantail::Sequence do
  let(:en_us_locale) { ICU4X::Locale.parse("en-US") }
  let(:en_locale) { ICU4X::Locale.parse("en") }
  let(:ja_locale) { ICU4X::Locale.parse("ja") }

  let(:en_us_bundle) do
    bundle = Fantail::Bundle.new(en_us_locale, use_isolating: false)
    resource = Fantail::Resource.from_string(<<~FTL)
      hello = Hello, {$name}!
      us-only = US English only
    FTL
    bundle.add_resource(resource)
    bundle
  end

  let(:en_bundle) do
    bundle = Fantail::Bundle.new(en_locale, use_isolating: false)
    resource = Fantail::Resource.from_string(<<~FTL)
      hello = Hello, {$name}!
      en-only = English only
    FTL
    bundle.add_resource(resource)
    bundle
  end

  let(:ja_bundle) do
    bundle = Fantail::Bundle.new(ja_locale, use_isolating: false)
    resource = Fantail::Resource.from_string(<<~FTL)
      hello = こんにちは、{$name}さん！
      ja-only = 日本語のみ
    FTL
    bundle.add_resource(resource)
    bundle
  end

  let(:sequence) { Fantail::Sequence.new(en_us_bundle, en_bundle, ja_bundle) }

  describe "#find" do
    context "with single ID" do
      it "returns the first bundle containing the message" do
        expect(sequence.find("hello")).to eq(en_us_bundle)
      end

      it "returns nil when message is not found" do
        expect(sequence.find("nonexistent")).to be_nil
      end

      it "returns fallback bundle when primary does not have the message" do
        expect(sequence.find("en-only")).to eq(en_bundle)
      end
    end

    context "with multiple IDs" do
      it "returns array of bundles for each ID" do
        result = sequence.find("us-only", "en-only", "ja-only")
        expect(result).to eq([en_us_bundle, en_bundle, ja_bundle])
      end

      it "returns nil for IDs not found" do
        result = sequence.find("hello", "nonexistent")
        expect(result).to eq([en_us_bundle, nil])
      end
    end
  end

  describe "#format" do
    it "formats message from the first matching bundle" do
      expect(sequence.format("hello", name: "World")).to eq("Hello, World!")
    end

    it "returns message ID when not found" do
      expect(sequence.format("nonexistent")).to eq("nonexistent")
    end

    it "uses fallback bundle when primary does not have the message" do
      expect(sequence.format("ja-only")).to eq("日本語のみ")
    end

    it "collects errors when errors array is provided" do
      errors = []
      result = sequence.format("hello", errors)
      expect(result).to eq("Hello, {$name}!")
      expect(errors).to include("Unknown variable: $name")
    end
  end

  describe "with empty sequence" do
    let(:empty_sequence) { Fantail::Sequence.new }

    it "returns nil for find" do
      expect(empty_sequence.find("hello")).to be_nil
    end

    it "returns message ID for format" do
      expect(empty_sequence.format("hello")).to eq("hello")
    end
  end

  describe "bundle priority" do
    it "returns first bundle when multiple bundles have the same message" do
      expect(sequence.find("hello")).to eq(en_us_bundle)
    end

    context "with reversed priority" do
      let(:reversed_sequence) { Fantail::Sequence.new(ja_bundle, en_bundle, en_us_bundle) }

      it "returns first bundle in the new order" do
        expect(reversed_sequence.find("hello")).to eq(ja_bundle)
      end

      it "formats using the first bundle" do
        expect(reversed_sequence.format("hello", name: "World")).to eq("こんにちは、Worldさん！")
      end
    end
  end
end
