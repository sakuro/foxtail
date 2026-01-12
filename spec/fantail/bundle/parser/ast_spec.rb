# frozen_string_literal: true

RSpec.describe Fantail::Bundle::Parser::AST do
  describe Fantail::Bundle::Parser::AST::StringLiteral do
    it "creates a string literal node" do
      result = Fantail::Bundle::Parser::AST::StringLiteral[value: "hello"]
      expect(result).to be_a(Fantail::Bundle::Parser::AST::StringLiteral)
      expect(result.value).to eq("hello")
    end

    it "converts non-string values to string" do
      result = Fantail::Bundle::Parser::AST::StringLiteral[value: 42]
      expect(result.value).to eq("42")
    end
  end

  describe Fantail::Bundle::Parser::AST::NumberLiteral do
    it "creates a number literal node with default precision" do
      result = Fantail::Bundle::Parser::AST::NumberLiteral[value: 42.5]
      expect(result).to be_a(Fantail::Bundle::Parser::AST::NumberLiteral)
      expect(result.value).to eq(42.5)
      expect(result.precision).to eq(0)
    end

    it "converts string numbers to float" do
      result = Fantail::Bundle::Parser::AST::NumberLiteral[value: "42.5"]
      expect(result.value).to eq(42.5)
      expect(result.precision).to eq(0)
    end

    it "includes precision when provided" do
      result = Fantail::Bundle::Parser::AST::NumberLiteral[value: 42.5, precision: 2]
      expect(result.value).to eq(42.5)
      expect(result.precision).to eq(2)
    end

    it "raises error when precision is nil" do
      expect {
        Fantail::Bundle::Parser::AST::NumberLiteral[value: 42.5, precision: nil]
      }.to raise_error(TypeError, /can't convert nil into Integer/)
    end
  end

  describe Fantail::Bundle::Parser::AST::VariableReference do
    it "creates a variable reference node" do
      result = Fantail::Bundle::Parser::AST::VariableReference[name: "username"]
      expect(result).to be_a(Fantail::Bundle::Parser::AST::VariableReference)
      expect(result.name).to eq("username")
    end

    it "converts non-string names to string" do
      result = Fantail::Bundle::Parser::AST::VariableReference[name: :username]
      expect(result.name).to eq("username")
    end
  end

  describe Fantail::Bundle::Parser::AST::TermReference do
    it "creates a term reference node" do
      result = Fantail::Bundle::Parser::AST::TermReference[name: "brand"]
      expect(result).to be_a(Fantail::Bundle::Parser::AST::TermReference)
      expect(result.name).to eq("brand")
      expect(result.attr).to be_nil
      expect(result.args).to eq([])
    end

    it "includes attribute when provided" do
      result = Fantail::Bundle::Parser::AST::TermReference[name: "brand", attr: "title"]
      expect(result.name).to eq("brand")
      expect(result.attr).to eq("title")
      expect(result.args).to eq([])
    end

    it "includes args when provided" do
      args = [Fantail::Bundle::Parser::AST::StringLiteral[value: "value"]]
      result = Fantail::Bundle::Parser::AST::TermReference[name: "brand", args:]
      expect(result.name).to eq("brand")
      expect(result.attr).to be_nil
      expect(result.args).to eq(args)
    end

    it "includes empty args array" do
      result = Fantail::Bundle::Parser::AST::TermReference[name: "brand", args: []]
      expect(result.args).to eq([])
    end
  end

  describe Fantail::Bundle::Parser::AST::MessageReference do
    it "creates a message reference node" do
      result = Fantail::Bundle::Parser::AST::MessageReference[name: "hello"]
      expect(result).to be_a(Fantail::Bundle::Parser::AST::MessageReference)
      expect(result.name).to eq("hello")
      expect(result.attr).to be_nil
    end

    it "includes attribute when provided" do
      result = Fantail::Bundle::Parser::AST::MessageReference[name: "hello", attr: "title"]
      expect(result.name).to eq("hello")
      expect(result.attr).to eq("title")
    end
  end

  describe Fantail::Bundle::Parser::AST::FunctionReference do
    it "creates a function reference node" do
      result = Fantail::Bundle::Parser::AST::FunctionReference[name: "NUMBER"]
      expect(result).to be_a(Fantail::Bundle::Parser::AST::FunctionReference)
      expect(result.name).to eq("NUMBER")
      expect(result.args).to eq([])
    end

    it "includes args when provided" do
      args = [Fantail::Bundle::Parser::AST::StringLiteral[value: "value"]]
      result = Fantail::Bundle::Parser::AST::FunctionReference[name: "NUMBER", args:]
      expect(result.name).to eq("NUMBER")
      expect(result.args).to eq(args)
    end

    it "includes empty args array" do
      result = Fantail::Bundle::Parser::AST::FunctionReference[name: "NUMBER", args: []]
      expect(result.args).to eq([])
    end
  end

  describe Fantail::Bundle::Parser::AST::SelectExpression do
    it "creates a select expression node" do
      selector = Fantail::Bundle::Parser::AST::VariableReference[name: "count"]
      variants = [
        Fantail::Bundle::Parser::AST::Variant[key: Fantail::Bundle::Parser::AST::NumberLiteral[value: 0], value: "none"],
        Fantail::Bundle::Parser::AST::Variant[key: Fantail::Bundle::Parser::AST::StringLiteral[value: "other"], value: "many"]
      ]

      result = Fantail::Bundle::Parser::AST::SelectExpression[selector:, variants:]
      expect(result).to be_a(Fantail::Bundle::Parser::AST::SelectExpression)
      expect(result.selector).to eq(selector)
      expect(result.variants).to eq(variants)
      expect(result.star).to eq(0)
    end

    it "accepts custom star index" do
      selector = Fantail::Bundle::Parser::AST::VariableReference[name: "count"]
      variants = [Fantail::Bundle::Parser::AST::Variant[key: Fantail::Bundle::Parser::AST::StringLiteral[value: "other"], value: "many"]]

      result = Fantail::Bundle::Parser::AST::SelectExpression[selector:, variants:, star: 1]
      expect(result.selector).to eq(selector)
      expect(result.variants).to eq(variants)
      expect(result.star).to eq(1)
    end
  end

  describe Fantail::Bundle::Parser::AST::Variant do
    it "creates a variant node" do
      key = Fantail::Bundle::Parser::AST::StringLiteral[value: "one"]
      value = "single item"

      result = Fantail::Bundle::Parser::AST::Variant[key:, value:]
      expect(result).to be_a(Fantail::Bundle::Parser::AST::Variant)
      expect(result.key).to eq(key)
      expect(result.value).to eq(value)
    end
  end

  describe Fantail::Bundle::Parser::AST::Message do
    it "creates a message node" do
      result = Fantail::Bundle::Parser::AST::Message[id: "hello"]
      expect(result).to be_a(Fantail::Bundle::Parser::AST::Message)
      expect(result.id).to eq("hello")
      expect(result.value).to be_nil
      expect(result.attributes).to be_nil
    end

    it "includes value when provided" do
      value = "Hello world"
      result = Fantail::Bundle::Parser::AST::Message[id: "hello", value:]
      expect(result.id).to eq("hello")
      expect(result.value).to eq(value)
    end

    it "includes attributes when provided" do
      attributes = {"title" => "Greeting"}
      result = Fantail::Bundle::Parser::AST::Message[id: "hello", attributes:]
      expect(result.id).to eq("hello")
      expect(result.attributes).to eq(attributes)
    end

    it "accepts nil attributes" do
      result = Fantail::Bundle::Parser::AST::Message[id: "hello", attributes: nil]
      expect(result.id).to eq("hello")
      expect(result.attributes).to be_nil
    end
  end

  describe Fantail::Bundle::Parser::AST::Term do
    it "creates a term definition node with - prefix" do
      value = "Firefox"
      result = Fantail::Bundle::Parser::AST::Term[id: "brand", value:]
      expect(result).to be_a(Fantail::Bundle::Parser::AST::Term)
      expect(result.id).to eq("-brand")
      expect(result.value).to eq(value)
    end

    it "preserves existing - prefix" do
      value = "Firefox"
      result = Fantail::Bundle::Parser::AST::Term[id: "-brand", value:]
      expect(result.id).to eq("-brand")
    end

    it "includes attributes when provided" do
      value = "Firefox"
      attributes = {"case" => "nominative"}
      result = Fantail::Bundle::Parser::AST::Term[id: "brand", value:, attributes:]
      expect(result.id).to eq("-brand")
      expect(result.value).to eq(value)
      expect(result.attributes).to eq(attributes)
    end

    it "accepts nil attributes" do
      value = "Firefox"
      result = Fantail::Bundle::Parser::AST::Term[id: "brand", value:, attributes: nil]
      expect(result.id).to eq("-brand")
      expect(result.attributes).to be_nil
    end
  end

  describe "type checking helpers" do
    describe ".literal?" do
      it "returns true for string literals" do
        node = Fantail::Bundle::Parser::AST::StringLiteral[value: "hello"]
        expect(Fantail::Bundle::Parser::AST.literal?(node)).to be true
      end

      it "returns true for number literals" do
        node = Fantail::Bundle::Parser::AST::NumberLiteral[value: 42]
        expect(Fantail::Bundle::Parser::AST.literal?(node)).to be true
      end

      it "returns false for non-literals" do
        node = Fantail::Bundle::Parser::AST::VariableReference[name: "name"]
        expect(Fantail::Bundle::Parser::AST.literal?(node)).to be false
      end

      it "returns false for non-Data values" do
        expect(Fantail::Bundle::Parser::AST.literal?("string")).to be false
        expect(Fantail::Bundle::Parser::AST.literal?(42)).to be false
      end
    end

    describe ".expression?" do
      it "returns true for literals" do
        str_node = Fantail::Bundle::Parser::AST::StringLiteral[value: "hello"]
        num_node = Fantail::Bundle::Parser::AST::NumberLiteral[value: 42]
        expect(Fantail::Bundle::Parser::AST.expression?(str_node)).to be true
        expect(Fantail::Bundle::Parser::AST.expression?(num_node)).to be true
      end

      it "returns true for variable references" do
        node = Fantail::Bundle::Parser::AST::VariableReference[name: "name"]
        expect(Fantail::Bundle::Parser::AST.expression?(node)).to be true
      end

      it "returns true for term references" do
        node = Fantail::Bundle::Parser::AST::TermReference[name: "brand"]
        expect(Fantail::Bundle::Parser::AST.expression?(node)).to be true
      end

      it "returns true for message references" do
        node = Fantail::Bundle::Parser::AST::MessageReference[name: "hello"]
        expect(Fantail::Bundle::Parser::AST.expression?(node)).to be true
      end

      it "returns true for function references" do
        node = Fantail::Bundle::Parser::AST::FunctionReference[name: "NUMBER"]
        expect(Fantail::Bundle::Parser::AST.expression?(node)).to be true
      end

      it "returns true for select expressions" do
        selector = Fantail::Bundle::Parser::AST::VariableReference[name: "count"]
        variants = [Fantail::Bundle::Parser::AST::Variant[key: Fantail::Bundle::Parser::AST::StringLiteral[value: "other"], value: "many"]]
        node = Fantail::Bundle::Parser::AST::SelectExpression[selector:, variants:]
        expect(Fantail::Bundle::Parser::AST.expression?(node)).to be true
      end

      it "returns false for non-expressions" do
        expect(Fantail::Bundle::Parser::AST.expression?("string")).to be false
        expect(Fantail::Bundle::Parser::AST.expression?(42)).to be false
        expect(Fantail::Bundle::Parser::AST.expression?({})).to be false
      end
    end

    describe ".pattern_element?" do
      it "returns true for strings" do
        expect(Fantail::Bundle::Parser::AST.pattern_element?("hello")).to be true
      end

      it "returns true for expressions" do
        node = Fantail::Bundle::Parser::AST::VariableReference[name: "name"]
        expect(Fantail::Bundle::Parser::AST.pattern_element?(node)).to be true
      end

      it "returns false for non-pattern elements" do
        expect(Fantail::Bundle::Parser::AST.pattern_element?(42)).to be false
        expect(Fantail::Bundle::Parser::AST.pattern_element?({})).to be false
      end
    end

    describe ".complex_pattern?" do
      it "returns true for arrays of pattern elements" do
        pattern = [
          "Hello, ",
          Fantail::Bundle::Parser::AST::VariableReference[name: "name"],
          "!"
        ]
        expect(Fantail::Bundle::Parser::AST.complex_pattern?(pattern)).to be true
      end

      it "returns false for arrays with non-pattern elements" do
        pattern = ["Hello", 42, "world"]
        expect(Fantail::Bundle::Parser::AST.complex_pattern?(pattern)).to be false
      end

      it "returns false for non-arrays" do
        expect(Fantail::Bundle::Parser::AST.complex_pattern?("string")).to be false
        expect(Fantail::Bundle::Parser::AST.complex_pattern?(42)).to be false
      end
    end

    describe ".pattern?" do
      it "returns true for simple string patterns" do
        expect(Fantail::Bundle::Parser::AST.pattern?("Hello world")).to be true
      end

      it "returns true for complex patterns" do
        pattern = ["Hello, ", Fantail::Bundle::Parser::AST::VariableReference[name: "name"]]
        expect(Fantail::Bundle::Parser::AST.pattern?(pattern)).to be true
      end

      it "returns false for non-patterns" do
        expect(Fantail::Bundle::Parser::AST.pattern?(42)).to be false
        expect(Fantail::Bundle::Parser::AST.pattern?({})).to be false
      end
    end
  end
end
