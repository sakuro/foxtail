# frozen_string_literal: true

RSpec.describe Fantail::Bundle do
  describe "#initialize" do
    it "accepts a single locale" do
      bundle = Fantail::Bundle.new(ICU4X::Locale.parse("en-US"))
      expect(bundle.locale.to_s).to eq("en-US")
    end

    it "rejects non-ICU4X::Locale arguments" do
      expect { Fantail::Bundle.new("en-US") }.to raise_error(ArgumentError, /must be an ICU4X::Locale/)
      expect { Fantail::Bundle.new(nil) }.to raise_error(ArgumentError, /must be an ICU4X::Locale/)
    end

    it "sets default options" do
      locale = ICU4X::Locale.parse("en")
      bundle = Fantail::Bundle.new(locale)
      expect(bundle.functions).to have_key("NUMBER")
      expect(bundle.functions).to have_key("DATETIME")
      expect(bundle.use_isolating?).to be true
      expect(bundle.transform).to be_nil
    end

    it "includes working default functions" do
      locale = ICU4X::Locale.parse("en")
      bundle = Fantail::Bundle.new(locale)
      number_func = bundle.functions["NUMBER"]
      datetime_func = bundle.functions["DATETIME"]

      expect(number_func.call(42, locale:)).to eq("42")
      expect(datetime_func.call(Time.new(2023, 6, 15), locale:)).to include("2023")
    end

    it "accepts custom options" do
      locale = ICU4X::Locale.parse("en")
      bundle = Fantail::Bundle.new(
        locale,
        use_isolating: false,
        transform: :some_transform
      )

      expect(bundle.use_isolating?).to be false
      expect(bundle.transform).to eq(:some_transform)
    end

    it "merges custom functions with defaults" do
      custom_function = ->(_val, _opts) { "custom" }
      locale = ICU4X::Locale.parse("en")
      bundle = Fantail::Bundle.new(locale, functions: {"CUSTOM" => custom_function})

      expect(bundle.functions).to have_key("NUMBER")
      expect(bundle.functions).to have_key("DATETIME")
      expect(bundle.functions).to have_key("CUSTOM")
      expect(bundle.functions["CUSTOM"]).to eq(custom_function)
    end

    it "allows overriding default functions" do
      custom_number = ->(val, _opts) { "custom:#{val}" }
      locale = ICU4X::Locale.parse("en")
      bundle = Fantail::Bundle.new(locale, functions: {"NUMBER" => custom_number})

      expect(bundle.functions["NUMBER"]).to eq(custom_number)
      expect(bundle.functions).to have_key("DATETIME")
    end
  end

  describe "#add_resource" do
    let(:bundle) { Fantail::Bundle.new(ICU4X::Locale.parse("en")) }
    let(:ftl_source) do
      <<~FTL
        hello = Hello, {$name}!
        -brand = Firefox
        goodbye = Goodbye world
      FTL
    end
    let(:resource) { Fantail::Resource.from_string(ftl_source) }

    it "adds resource entries to the bundle" do
      bundle.add_resource(resource)

      expect(bundle.message?("hello")).to be true
      expect(bundle.message?("goodbye")).to be true
      expect(bundle.term?("-brand")).to be true
    end

    it "returns self for method chaining" do
      result = bundle.add_resource(resource)
      expect(result).to be(bundle)
    end

    it "prevents overrides by default" do
      bundle.add_resource(resource)

      # Add same resource again
      duplicate_resource = Fantail::Resource.from_string("hello = Different message")
      bundle.add_resource(duplicate_resource)

      # Should still have original message
      message = bundle.message("hello")
      expect(message.value).to be_an(Array) # Original complex pattern
    end

    it "allows overrides when specified" do
      bundle.add_resource(resource)

      # Add resource with override
      override_resource = Fantail::Resource.from_string("hello = Different message")
      bundle.add_resource(override_resource, allow_overrides: true)

      # Should have new message
      message = bundle.message("hello")
      expect(message.value).to eq("Different message")
    end
  end

  describe "#message? and #message" do
    let(:bundle) { Fantail::Bundle.new(ICU4X::Locale.parse("en")) }
    let(:resource) { Fantail::Resource.from_string("hello = Hello world") }

    before { bundle.add_resource(resource) }

    it "checks message existence" do
      expect(bundle.message?("hello")).to be true
      expect(bundle.message?("nonexistent")).to be false
    end

    it "retrieves messages" do
      message = bundle.message("hello")
      expect(message).to be_a(Fantail::Bundle::Parser::AST::Message)
      expect(message.id).to eq("hello")
      expect(message.attributes).to be_nil
    end

    it "returns nil for nonexistent messages" do
      expect(bundle.message("nonexistent")).to be_nil
    end

    it "handles string and symbol keys" do
      expect(bundle.message?(:hello)).to be true
      expect(bundle.message(:hello)).not_to be_nil
    end
  end

  describe "#term? and #term" do
    let(:bundle) { Fantail::Bundle.new(ICU4X::Locale.parse("en")) }
    let(:resource) { Fantail::Resource.from_string("-brand = Firefox") }

    before { bundle.add_resource(resource) }

    it "checks term existence" do
      expect(bundle.term?("-brand")).to be true
      expect(bundle.term?("nonexistent")).to be false
    end

    it "retrieves terms" do
      term = bundle.term("-brand")
      expect(term).to be_a(Fantail::Bundle::Parser::AST::Term)
      expect(term.id).to eq("-brand")
      expect(term.attributes).to be_nil
    end

    it "returns nil for nonexistent terms" do
      expect(bundle.term("nonexistent")).to be_nil
    end
  end

  describe "#format" do
    let(:bundle) { Fantail::Bundle.new(ICU4X::Locale.parse("en"), use_isolating: false) }

    context "with simple messages" do
      before do
        resource = Fantail::Resource.from_string("hello = Hello world")
        bundle.add_resource(resource)
      end

      it "formats simple text messages" do
        result = bundle.format("hello")
        expect(result).to eq("Hello world")
      end

      it "returns message ID for nonexistent messages" do
        result = bundle.format("nonexistent")
        expect(result).to eq("nonexistent")
      end
    end

    context "with variable substitution" do
      before do
        resource = Fantail::Resource.from_string("greeting = Hello, {$name}!")
        bundle.add_resource(resource)
      end

      it "substitutes variables" do
        result = bundle.format("greeting", name: "World")
        expect(result).to eq("Hello, World!")
      end

      it "handles missing variables" do
        result = bundle.format("greeting")
        expect(result).to eq("Hello, {$name}!")
      end

      it "handles multiple variables" do
        result1 = bundle.format("greeting", name: "Alice")
        result2 = bundle.format("greeting", name: "Bob")
        expect(result1).to eq("Hello, Alice!")
        expect(result2).to eq("Hello, Bob!")
      end
    end

    context "with term references" do
      before do
        ftl = <<~FTL
          hello = Hello from {-brand}!
          -brand = Firefox
        FTL
        resource = Fantail::Resource.from_string(ftl)
        bundle.add_resource(resource)
      end

      it "expands term references" do
        result = bundle.format("hello")
        expect(result).to eq("Hello from Firefox!")
      end
    end

    context "with select expressions" do
      before do
        ftl = <<~FTL
          emails = You have {$count ->
            [0] no emails
            [one] one email
           *[other] {$count} emails
          }.
        FTL
        resource = Fantail::Resource.from_string(ftl)
        bundle.add_resource(resource)
      end

      it "handles select expressions with number matching" do
        result = bundle.format("emails", count: 0)
        expect(result).to eq("You have no emails.")
      end

      it "handles select expressions with default variant" do
        result = bundle.format("emails", count: 5)
        expect(result).to eq("You have 5 emails.")
      end
    end
  end

  describe "#format_pattern" do
    let(:bundle) { Fantail::Bundle.new(ICU4X::Locale.parse("en"), use_isolating: false) }

    it "formats string patterns" do
      result = bundle.format_pattern("Hello world")
      expect(result).to eq("Hello world")
    end

    it "formats array patterns" do
      pattern = ["Hello, ", Fantail::Bundle::Parser::AST::VariableReference[name: "name"], "!"]
      result = bundle.format_pattern(pattern, name: "World")
      expect(result).to eq("Hello, World!")
    end

    it "collects errors when provided" do
      pattern = [Fantail::Bundle::Parser::AST::VariableReference[name: "missing"]]
      errors = []
      result = bundle.format_pattern(pattern, errors)

      expect(result).to eq("{$missing}")
      expect(errors).not_to be_empty
      expect(errors.first).to include("Unknown variable")
    end
  end
end
