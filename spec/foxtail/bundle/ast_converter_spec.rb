# frozen_string_literal: true

RSpec.describe Foxtail::Bundle::ASTConverter do
  let(:converter) { Foxtail::Bundle::ASTConverter.new }

  describe "#initialize" do
    it "sets default options" do
      expect(converter.errors).to eq([])
    end

    it "accepts custom options" do
      custom_converter = Foxtail::Bundle::ASTConverter.new(skip_junk: false, skip_comments: false)
      expect(custom_converter.errors).to eq([])
    end
  end

  describe "#convert_resource" do
    let(:ftl_source) do
      <<~FTL
        hello = Hello, {$name}!
        -brand = Firefox
        goodbye = Goodbye!
      FTL
    end

    let(:parser_resource) { Foxtail::Parser.new.parse(ftl_source) }

    it "converts parser resource to bundle AST entries" do
      entries = converter.convert_resource(parser_resource)

      expect(entries).to be_an(Array)
      expect(entries.length).to eq(3)

      # Check message
      hello_msg = entries[0]
      expect(hello_msg["type"]).to eq("message")
      expect(hello_msg["id"]).to eq("hello")
      expect(hello_msg["value"]).to be_an(Array)

      # Check term
      brand_term = entries[1]
      expect(brand_term["type"]).to eq("term")
      expect(brand_term["id"]).to eq("-brand")
      expect(brand_term["value"]).to eq("Firefox")

      # Check simple message
      goodbye_msg = entries[2]
      expect(goodbye_msg["type"]).to eq("message")
      expect(goodbye_msg["id"]).to eq("goodbye")
      expect(goodbye_msg["value"]).to eq("Goodbye!")
    end
  end

  describe "#convert_message" do
    let(:ftl_source) { "hello = Hello, {$name}!" }
    let(:parser_resource) { Foxtail::Parser.new.parse(ftl_source) }
    let(:parser_message) { parser_resource.body.first }

    it "converts parser message to bundle AST message" do
      result = converter.convert_message(parser_message)

      expect(result["type"]).to eq("message")
      expect(result["id"]).to eq("hello")
      expect(result["value"]).to be_an(Array)
      expect(result["value"][0]).to eq("Hello, ")
      expect(result["value"][1]["type"]).to eq("var")
      expect(result["value"][1]["name"]).to eq("name")
      expect(result["value"][2]).to eq("!")
    end

    context "with attributes" do
      let(:ftl_source) do
        <<~FTL
          hello = Hello world
              .title = Page title
        FTL
      end

      it "converts message attributes" do
        result = converter.convert_message(parser_message)

        expect(result["attributes"]).to be_a(Hash)
        expect(result["attributes"]["title"]).to eq("Page title")
      end
    end
  end

  describe "#convert_term" do
    let(:ftl_source) { "-brand = Firefox" }
    let(:parser_resource) { Foxtail::Parser.new.parse(ftl_source) }
    let(:parser_term) { parser_resource.body.first }

    it "converts parser term to bundle AST term" do
      result = converter.convert_term(parser_term)

      expect(result["type"]).to eq("term")
      expect(result["id"]).to eq("-brand")
      expect(result["value"]).to eq("Firefox")
    end
  end

  describe "pattern conversion" do
    describe "#convert_pattern" do
      it "handles string patterns" do
        result = converter.__send__(:convert_pattern, "Hello world")
        expect(result).to eq("Hello world")
      end

      it "handles nil patterns" do
        result = converter.__send__(:convert_pattern, nil)
        expect(result).to be_nil
      end
    end

    describe "#convert_complex_pattern" do
      let(:ftl_source) { "hello = Hello, {$name}!" }
      let(:parser_resource) { Foxtail::Parser.new.parse(ftl_source) }
      let(:parser_message) { parser_resource.body.first }
      let(:pattern_elements) { parser_message.value.elements }

      it "converts array of pattern elements" do
        result = converter.__send__(:convert_complex_pattern, pattern_elements)

        expect(result).to be_an(Array)
        expect(result[0]).to eq("Hello, ")
        expect(result[1]["type"]).to eq("var")
        expect(result[1]["name"]).to eq("name")
        expect(result[2]).to eq("!")
      end
    end
  end

  describe "expression conversion" do
    let(:ftl_source) { "test = {$var} {hello} {-term} {NUMBER($count)}" }
    let(:parser_resource) { Foxtail::Parser.new.parse(ftl_source) }
    let(:pattern_elements) { parser_resource.body.first.value.elements }

    it "converts variable references" do
      var_placeable = pattern_elements[0]
      result = converter.__send__(:convert_expression, var_placeable.expression)

      expect(result["type"]).to eq("var")
      expect(result["name"]).to eq("var")
    end

    it "converts message references" do
      msg_placeable = pattern_elements[2]
      result = converter.__send__(:convert_expression, msg_placeable.expression)

      expect(result["type"]).to eq("mesg")
      expect(result["name"]).to eq("hello")
    end

    it "converts term references" do
      term_placeable = pattern_elements[4]
      result = converter.__send__(:convert_expression, term_placeable.expression)

      expect(result["type"]).to eq("term")
      expect(result["name"]).to eq("term")
    end

    it "converts function references with positional arguments" do
      func_placeable = pattern_elements[6]
      result = converter.__send__(:convert_expression, func_placeable.expression)

      expect(result["type"]).to eq("func")
      expect(result["name"]).to eq("NUMBER")
      expect(result["args"]).to be_an(Array)
      expect(result["args"].length).to eq(1)
      expect(result["args"][0]["type"]).to eq("var")
      expect(result["args"][0]["name"]).to eq("count")
    end

    it "converts function references with named arguments" do
      ftl_source = "test = {FUNC(arg1: 1, arg2: \"hello\")}"
      parser_resource = Foxtail::Parser.new.parse(ftl_source)
      func_placeable = parser_resource.body.first.value.elements[0]
      result = converter.__send__(:convert_expression, func_placeable.expression)

      expect(result["type"]).to eq("func")
      expect(result["name"]).to eq("FUNC")
      expect(result["args"]).to be_an(Array)
      expect(result["args"].length).to eq(2)

      # First named argument
      expect(result["args"][0]["type"]).to eq("narg")
      expect(result["args"][0]["name"]).to eq("arg1")
      expect(result["args"][0]["value"]["type"]).to eq("num")
      expect(result["args"][0]["value"]["value"]).to eq(1.0)

      # Second named argument
      expect(result["args"][1]["type"]).to eq("narg")
      expect(result["args"][1]["name"]).to eq("arg2")
      expect(result["args"][1]["value"]["type"]).to eq("str")
      expect(result["args"][1]["value"]["value"]).to eq("hello")
    end

    it "processes escape sequences in text elements" do
      ftl_source = "test = Text with \\\"quotes\\\" and \\\\backslash and \\u0041"
      parser_resource = Foxtail::Parser.new.parse(ftl_source)
      result = converter.convert_resource(parser_resource)

      expect(result.first["value"]).to eq("Text with \"quotes\" and \\backslash and A")
    end
  end

  describe "select expression conversion" do
    let(:ftl_source) do
      <<~FTL
        emails = You have {$count ->
          [0] no emails
          [one] one email
         *[other] {$count} emails
        }.
      FTL
    end

    let(:parser_resource) { Foxtail::Parser.new.parse(ftl_source) }
    let(:select_expr) { parser_resource.body.first.value.elements[1].expression }

    it "converts select expressions" do
      result = converter.__send__(:convert_expression, select_expr)

      expect(result["type"]).to eq("select")
      expect(result["selector"]["type"]).to eq("var")
      expect(result["selector"]["name"]).to eq("count")
      expect(result["variants"]).to be_an(Array)
      expect(result["variants"].length).to eq(3)
      expect(result["star"]).to eq(2) # Index of default variant
    end

    it "converts variant keys correctly" do
      result = converter.__send__(:convert_expression, select_expr)
      variants = result["variants"]

      # Number literal key
      expect(variants[0]["key"]["type"]).to eq("num")
      expect(variants[0]["key"]["value"]).to eq(0.0)

      # String literal key
      expect(variants[1]["key"]["type"]).to eq("str")
      expect(variants[1]["key"]["value"]).to eq("one")

      # Default variant key
      expect(variants[2]["key"]["type"]).to eq("str")
      expect(variants[2]["key"]["value"]).to eq("other")
    end
  end

  describe "literal conversion" do
    let(:ftl_source) do
      <<~FTL
        test = {$count ->
          [0] no items
          [one] one item
         *[other] {$count} items
        }
      FTL
    end

    let(:parser_resource) { Foxtail::Parser.new.parse(ftl_source) }
    let(:select_expr) { parser_resource.body.first.value.elements.first.expression }

    describe "#convert_literal" do
      it "converts number literals from select expression" do
        zero_variant = select_expr.variants[0]
        result = converter.__send__(:convert_literal, zero_variant.key)
        expect(result["type"]).to eq("num")
        expect(result["value"]).to eq(0.0)
      end

      it "converts identifier literals from select expression" do
        one_variant = select_expr.variants[1]
        result = converter.__send__(:convert_literal, one_variant.key)
        expect(result["type"]).to eq("str")
        expect(result["value"]).to eq("one")
      end

      it "converts default identifier literals from select expression" do
        other_variant = select_expr.variants[2]
        result = converter.__send__(:convert_literal, other_variant.key)
        expect(result["type"]).to eq("str")
        expect(result["value"]).to eq("other")
      end
    end
  end
end
