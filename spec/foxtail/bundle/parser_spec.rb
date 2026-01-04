# frozen_string_literal: true

RSpec.describe Foxtail::Bundle::Parser do
  let(:parser) { Foxtail::Bundle::Parser.new }

  describe "#parse" do
    describe "simple messages" do
      it "parses a simple message with inline text" do
        result = parser.parse("hello = Hello world")
        expect(result.length).to eq(1)
        message = result.first
        expect(message).to be_a(Foxtail::Bundle::AST::Message)
        expect(message.id).to eq("hello")
        expect(message.value).to eq("Hello world")
      end

      it "parses multiple messages" do
        ftl = <<~FTL
          hello = Hello
          goodbye = Goodbye
        FTL
        result = parser.parse(ftl)
        expect(result.length).to eq(2)
        expect(result[0].id).to eq("hello")
        expect(result[0].value).to eq("Hello")
        expect(result[1].id).to eq("goodbye")
        expect(result[1].value).to eq("Goodbye")
      end

      it "strips trailing spaces from inline patterns" do
        result = parser.parse("hello = Hello   ")
        expect(result.first.value).to eq("Hello")
      end
    end

    describe "terms" do
      it "parses terms with leading dash" do
        result = parser.parse("-brand = Firefox")
        expect(result.length).to eq(1)
        term = result.first
        expect(term).to be_a(Foxtail::Bundle::AST::Term)
        expect(term.id).to eq("-brand")
        expect(term.value).to eq("Firefox")
      end
    end

    describe "attributes" do
      it "parses message with attributes" do
        ftl = <<~FTL
          hello = Hello
              .tooltip = Tooltip text
        FTL
        result = parser.parse(ftl)
        expect(result.length).to eq(1)
        message = result.first
        expect(message.value).to eq("Hello")
        expect(message.attributes).to eq({"tooltip" => "Tooltip text"})
      end

      it "parses message with multiple attributes" do
        ftl = <<~FTL
          button =
              .label = Click me
              .tooltip = A button
        FTL
        result = parser.parse(ftl)
        message = result.first
        expect(message.value).to be_nil
        expect(message.attributes).to eq({
          "label" => "Click me",
          "tooltip" => "A button"
        })
      end
    end

    describe "placeables" do
      it "parses message with variable reference" do
        result = parser.parse("hello = Hello { $name }")
        message = result.first
        expect(message.value).to be_a(Array)
        expect(message.value.length).to eq(2)
        expect(message.value[0]).to eq("Hello ")
        expect(message.value[1]).to be_a(Foxtail::Bundle::AST::VariableReference)
        expect(message.value[1].name).to eq("name")
      end

      it "parses message with message reference" do
        result = parser.parse("hello = Hello { other }")
        message = result.first
        expect(message.value).to be_a(Array)
        expect(message.value[1]).to be_a(Foxtail::Bundle::AST::MessageReference)
        expect(message.value[1].name).to eq("other")
      end

      it "parses message with term reference" do
        result = parser.parse("hello = Hello { -brand }")
        message = result.first
        expect(message.value).to be_a(Array)
        expect(message.value[1]).to be_a(Foxtail::Bundle::AST::TermReference)
        expect(message.value[1].name).to eq("brand")
      end

      it "parses message with function call" do
        result = parser.parse("hello = { NUMBER($count) }")
        message = result.first
        expect(message.value).to be_a(Array)
        expect(message.value[0]).to be_a(Foxtail::Bundle::AST::FunctionReference)
        expect(message.value[0].name).to eq("NUMBER")
        expect(message.value[0].args.length).to eq(1)
      end
    end

    describe "select expressions" do
      it "parses select expression with string variants" do
        ftl = <<~FTL
          hello = { $gender ->
              [male] Hello sir
             *[other] Hello
          }
        FTL
        result = parser.parse(ftl)
        message = result.first
        expect(message.value).to be_a(Array)
        select = message.value[0]
        expect(select).to be_a(Foxtail::Bundle::AST::SelectExpression)
        expect(select.variants.length).to eq(2)
        expect(select.star).to eq(1) # Default variant index
      end

      it "parses select expression with number variants" do
        ftl = <<~FTL
          items = { $count ->
              [0] No items
              [1] One item
             *[other] { $count } items
          }
        FTL
        result = parser.parse(ftl)
        message = result.first
        select = message.value[0]
        expect(select.variants[0].key).to be_a(Foxtail::Bundle::AST::NumberLiteral)
        expect(select.variants[0].key.value).to eq(0.0)
      end
    end

    describe "literals" do
      it "parses number literals" do
        result = parser.parse("value = { 42 }")
        message = result.first
        expect(message.value[0]).to be_a(Foxtail::Bundle::AST::NumberLiteral)
        expect(message.value[0].value).to eq(42.0)
        expect(message.value[0].precision).to eq(0)
      end

      it "parses number literals with decimals" do
        result = parser.parse("value = { 3.14 }")
        message = result.first
        expect(message.value[0]).to be_a(Foxtail::Bundle::AST::NumberLiteral)
        expect(message.value[0].value).to eq(3.14)
        expect(message.value[0].precision).to eq(2)
      end

      it "parses negative number literals" do
        result = parser.parse("value = { -42 }")
        message = result.first
        expect(message.value[0].value).to eq(-42.0)
      end

      it "parses string literals" do
        result = parser.parse('value = { "hello" }')
        message = result.first
        expect(message.value[0]).to be_a(Foxtail::Bundle::AST::StringLiteral)
        expect(message.value[0].value).to eq("hello")
      end

      it "parses string literals with escape sequences" do
        result = parser.parse('value = { "hello\\"world" }')
        message = result.first
        expect(message.value[0].value).to eq('hello"world')
      end

      it "parses string literals with unicode escapes" do
        result = parser.parse('value = { "\\u263A" }')
        message = result.first
        expect(message.value[0].value).to eq("☺")
      end
    end

    describe "named arguments" do
      it "parses function with named arguments" do
        result = parser.parse('value = { NUMBER($count, style: "currency") }')
        message = result.first
        func = message.value[0]
        expect(func).to be_a(Foxtail::Bundle::AST::FunctionReference)
        expect(func.args.length).to eq(2)
        expect(func.args[1]).to be_a(Foxtail::Bundle::AST::NamedArgument)
        expect(func.args[1].name).to eq("style")
        expect(func.args[1].value.value).to eq("currency")
      end
    end

    describe "multiline patterns" do
      it "parses block text patterns" do
        ftl = <<~FTL
          multiline =
              First line
              Second line
        FTL
        result = parser.parse(ftl)
        message = result.first
        expect(message.value).to be_a(Array)
        # Block patterns are complex patterns
      end
    end

    describe "error recovery" do
      it "skips invalid entries and continues parsing" do
        ftl = <<~FTL
          valid1 = Hello
          invalid entry without equals
          valid2 = World
        FTL
        result = parser.parse(ftl)
        expect(result.length).to eq(2)
        expect(result[0].id).to eq("valid1")
        expect(result[1].id).to eq("valid2")
      end

      it "returns empty array for completely invalid input" do
        result = parser.parse("this is not valid FTL at all")
        expect(result).to eq([])
      end
    end

    describe "comments are ignored" do
      it "ignores comments (runtime parser optimization)" do
        ftl = <<~FTL
          # This is a comment
          hello = Hello
        FTL
        result = parser.parse(ftl)
        expect(result.length).to eq(1)
        expect(result.first.id).to eq("hello")
      end
    end

    describe "attribute references" do
      it "parses message reference with attribute" do
        result = parser.parse("hello = { other.attr }")
        message = result.first
        ref = message.value[0]
        expect(ref).to be_a(Foxtail::Bundle::AST::MessageReference)
        expect(ref.name).to eq("other")
        expect(ref.attr).to eq("attr")
      end

      it "parses term reference with attribute" do
        result = parser.parse("hello = { -brand.short }")
        message = result.first
        ref = message.value[0]
        expect(ref).to be_a(Foxtail::Bundle::AST::TermReference)
        expect(ref.name).to eq("brand")
        expect(ref.attr).to eq("short")
      end
    end
  end
end
