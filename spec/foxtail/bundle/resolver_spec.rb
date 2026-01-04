# frozen_string_literal: true

RSpec.describe Foxtail::Bundle::Resolver do
  # Convenience alias for AST classes
  let(:ast) { Foxtail::Bundle::AST }

  let(:bundle) { Foxtail::Bundle.new(ICU4X::Locale.parse("en")) }
  let(:resolver) { Foxtail::Bundle::Resolver.new(bundle) }
  let(:scope) { Foxtail::Bundle::Scope.new(bundle, name: "World", count: 5) }

  describe "#initialize" do
    it "stores the bundle reference" do
      expect(resolver.instance_variable_get(:@bundle)).to eq(bundle)
    end
  end

  describe "#resolve_pattern" do
    it "returns string patterns as-is" do
      result = resolver.resolve_pattern("Hello world", scope)
      expect(result).to eq("Hello world")
    end

    it "resolves array patterns" do
      pattern = ["Hello, ", ast::VariableReference[name: "name"], "!"]
      result = resolver.resolve_pattern(pattern, scope)
      expect(result).to eq("Hello, World!")
    end

    it "resolves single expression patterns" do
      pattern = ast::VariableReference[name: "name"]
      result = resolver.resolve_pattern(pattern, scope)
      expect(result).to eq("World")
    end

    it "handles unknown pattern types" do
      result = resolver.resolve_pattern(42, scope)
      expect(result).to eq("42")
    end
  end

  describe "#resolve_expression" do
    it "resolves string literals" do
      expr = ast::StringLiteral[value: "hello"]
      result = resolver.resolve_expression(expr, scope)
      expect(result).to eq("hello")
    end

    it "resolves number literals" do
      expr = ast::NumberLiteral[value: 42.5]
      result = resolver.resolve_expression(expr, scope)
      expect(result).to eq(42.5)
    end

    it "resolves number literals with precision" do
      expr = ast::NumberLiteral[value: 42.567, precision: 2]
      result = resolver.resolve_expression(expr, scope)
      expect(result).to eq(42.567)
    end

    it "resolves variable references" do
      expr = ast::VariableReference[name: "name"]
      result = resolver.resolve_expression(expr, scope)
      expect(result).to eq("World")
    end

    it "handles missing variables" do
      expr = ast::VariableReference[name: "missing"]
      result = resolver.resolve_expression(expr, scope)
      expect(result).to eq("{$missing}")
      expect(scope.errors).to include("Unknown variable: $missing")
    end

    it "handles unknown expression types" do
      # Create a mock object that isn't a known expression type
      unknown_expr = Object.new
      result = resolver.resolve_expression(unknown_expr, scope)
      expect(result).to include("Object")
      expect(scope.errors.any? {|e| e.include?("Unknown expression type") }).to be true
    end
  end

  describe "#resolve_term_reference" do
    let(:ftl_source) { "-brand = Firefox" }
    let(:resource) { Foxtail::Resource.from_string(ftl_source) }

    before { bundle.add_resource(resource) }

    it "resolves term references" do
      expr = ast::TermReference[name: "brand"]
      result = resolver.resolve_expression(expr, scope)
      expect(result).to eq("Firefox")
    end

    it "handles missing terms" do
      expr = ast::TermReference[name: "missing"]
      result = resolver.resolve_expression(expr, scope)
      expect(result).to eq("{-missing}")
      expect(scope.errors).to include("Unknown term: -missing")
    end

    it "detects circular references" do
      # Create circular reference using separate resources
      resource_a = Foxtail::Resource.from_string("-a = {-b}")
      resource_b = Foxtail::Resource.from_string("-b = {-a}")
      bundle.add_resource(resource_a, allow_overrides: true)
      bundle.add_resource(resource_b, allow_overrides: true)

      expr = ast::TermReference[name: "a"]
      result = resolver.resolve_expression(expr, scope)
      # Should return the circular reference fallback
      expect(result).to match(/\{-[ab]\}/)
      expect(scope.errors.any? {|e| e.include?("Circular reference detected") }).to be true
    end
  end

  describe "#resolve_message_reference" do
    let(:ftl_source) { "hello = Hello world" }
    let(:resource) { Foxtail::Resource.from_string(ftl_source) }

    before { bundle.add_resource(resource) }

    it "resolves message references" do
      expr = ast::MessageReference[name: "hello"]
      result = resolver.resolve_expression(expr, scope)
      expect(result).to eq("Hello world")
    end

    it "handles missing messages" do
      expr = ast::MessageReference[name: "missing"]
      result = resolver.resolve_expression(expr, scope)
      expect(result).to eq("{missing}")
      expect(scope.errors).to include("Unknown message: missing")
    end
  end

  describe "#resolve_function_call" do
    let(:test_function) { ->(*args, **_options) { "Function result: #{args[0]}" } }
    let(:bundle_with_func) { Foxtail::Bundle.new(ICU4X::Locale.parse("en"), functions: {"TEST" => test_function}) }
    let(:resolver_with_func) { Foxtail::Bundle::Resolver.new(bundle_with_func) }

    it "resolves function calls" do
      expr = ast::FunctionReference[name: "TEST", args: [ast::StringLiteral[value: "input"]]]
      result = resolver_with_func.resolve_expression(expr, scope)
      expect(result).to eq("Function result: input")
    end

    it "handles missing functions" do
      expr = ast::FunctionReference[name: "MISSING", args: []]
      result = resolver.resolve_expression(expr, scope)
      expect(result).to eq("{MISSING()}")
      expect(scope.errors).to include("Unknown function: MISSING")
    end

    it "handles function errors" do
      error_function = ->(*_args, **_options) { raise RuntimeError, "Test error" }
      bundle_with_error = Foxtail::Bundle.new(ICU4X::Locale.parse("en"), functions: {"ERROR" => error_function})
      resolver_with_error = Foxtail::Bundle::Resolver.new(bundle_with_error)

      expr = ast::FunctionReference[name: "ERROR", args: []]
      result = resolver_with_error.resolve_expression(expr, scope)
      expect(result).to eq("{ERROR()}")
      expect(scope.errors).to include("Function error in ERROR: Test error")
    end

    it "resolves function calls with named arguments" do
      options_function = ->(*args, **options) { "#{args[0]} with options: #{options.inspect}" }
      bundle_with_options = Foxtail::Bundle.new(ICU4X::Locale.parse("en"), functions: {"FORMAT" => options_function})
      resolver_with_options = Foxtail::Bundle::Resolver.new(bundle_with_options)

      expr = ast::FunctionReference[name: "FORMAT", args: [
        ast::NumberLiteral[value: 42.5],
        ast::NamedArgument[name: "style", value: ast::StringLiteral[value: "currency"]],
        ast::NamedArgument[name: "minimumFractionDigits", value: ast::NumberLiteral[value: 2.0]]
      ]]

      result = resolver_with_options.resolve_expression(expr, scope)
      expect(result).to include("42.5")
      expect(result).to include("style")
      expect(result).to include("currency")
      expect(result).to include("minimumFractionDigits")
      expect(result).to include("2")
    end

    it "resolves NUMBER function calls with named arguments" do
      # Test with actual NUMBER function
      expr = ast::FunctionReference[name: "NUMBER", args: [
        ast::NumberLiteral[value: 1234.56],
        ast::NamedArgument[name: "minimumFractionDigits", value: ast::NumberLiteral[value: 2.0]]
      ]]

      result = resolver.resolve_expression(expr, scope)
      expect(result).to eq("1,234.56") # Should format with 2 decimal places (with locale formatting)
    end
  end

  describe "#resolve_select_expression" do
    it "resolves select expressions with number matching" do
      expr = ast::SelectExpression[
        selector: ast::VariableReference[name: "count"],
        variants: [
          ast::Variant[key: ast::NumberLiteral[value: 0], value: "none"],
          ast::Variant[key: ast::NumberLiteral[value: 5], value: "five"],
          ast::Variant[key: ast::StringLiteral[value: "other"], value: "many"]
        ],
        star: 2
      ]

      result = resolver.resolve_expression(expr, scope)
      expect(result).to eq("five")
    end

    it "uses default variant when no match" do
      expr = ast::SelectExpression[
        selector: ast::VariableReference[name: "count"],
        variants: [
          ast::Variant[key: ast::NumberLiteral[value: 0], value: "none"],
          ast::Variant[key: ast::StringLiteral[value: "other"], value: "many"]
        ],
        star: 1
      ]

      result = resolver.resolve_expression(expr, scope)
      expect(result).to eq("many")
    end

    it "resolves complex variant values" do
      expr = ast::SelectExpression[
        selector: ast::VariableReference[name: "count"],
        variants: [
          ast::Variant[
            key: ast::NumberLiteral[value: 5],
            value: ["You have ", ast::VariableReference[name: "count"], " items"]
          ]
        ],
        star: 0
      ]

      result = resolver.resolve_expression(expr, scope)
      expect(result).to eq("You have 5 items")
    end
  end

  describe "attribute resolution" do
    let(:ftl_source) do
      <<~FTL
        hello = Hello world
            .title = Greeting
        -brand = Firefox
            .version = 89.0
      FTL
    end
    let(:resource) { Foxtail::Resource.from_string(ftl_source) }

    before { bundle.add_resource(resource) }

    it "resolves message attributes" do
      expr = ast::MessageReference[name: "hello", attr: "title"]
      result = resolver.resolve_expression(expr, scope)
      expect(result).to eq("Greeting")
    end

    it "resolves term attributes" do
      expr = ast::TermReference[name: "brand", attr: "version"]
      result = resolver.resolve_expression(expr, scope)
      expect(result).to eq("89.0")
    end

    it "handles missing attributes" do
      expr = ast::MessageReference[name: "hello", attr: "missing"]
      result = resolver.resolve_expression(expr, scope)
      expect(result).to eq("{hello.missing}")
      expect(scope.errors).to include("Unknown message attribute: hello.missing")
    end
  end

  describe "plural category matching" do
    it "matches plural categories using ICU4X plural rules" do
      # Test English plural rules (1 is "one", others are "other")
      expr = ast::SelectExpression[
        selector: ast::VariableReference[name: "count"],
        variants: [
          ast::Variant[key: ast::StringLiteral[value: "one"], value: "one item"],
          ast::Variant[key: ast::StringLiteral[value: "other"], value: "many items"]
        ],
        star: 1
      ]

      # Test count = 1 (should match "one")
      scope_with_one = Foxtail::Bundle::Scope.new(bundle, count: 1)
      result = resolver.resolve_expression(expr, scope_with_one)
      expect(result).to eq("one item")

      # Test count = 2 (should match "other")
      scope_with_two = Foxtail::Bundle::Scope.new(bundle, count: 2)
      result = resolver.resolve_expression(expr, scope_with_two)
      expect(result).to eq("many items")
    end

    it "handles numeric selectors with string variants" do
      expr = ast::SelectExpression[
        selector: ast::VariableReference[name: "count"],
        variants: [
          ast::Variant[key: ast::NumberLiteral[value: 0], value: "no items"],
          ast::Variant[key: ast::StringLiteral[value: "one"], value: "one item"],
          ast::Variant[key: ast::StringLiteral[value: "other"], value: "many items"]
        ],
        star: 2
      ]

      # Exact numeric match should take precedence
      scope_with_zero = Foxtail::Bundle::Scope.new(bundle, count: 0)
      result = resolver.resolve_expression(expr, scope_with_zero)
      expect(result).to eq("no items")

      # Plural rule matching for non-exact matches
      scope_with_one = Foxtail::Bundle::Scope.new(bundle, count: 1)
      result = resolver.resolve_expression(expr, scope_with_one)
      expect(result).to eq("one item")
    end

    it "falls back to default when plural rules fail" do
      # Test with unsupported locale that might fail plural rule evaluation
      plural_rules_double = instance_double(ICU4X::PluralRules)
      allow(ICU4X::PluralRules).to receive(:new).and_return(plural_rules_double)
      allow(plural_rules_double).to receive(:select).and_raise("Error")

      expr = ast::SelectExpression[
        selector: ast::VariableReference[name: "count"],
        variants: [
          ast::Variant[key: ast::StringLiteral[value: "one"], value: "one item"],
          ast::Variant[key: ast::StringLiteral[value: "other"], value: "many items"]
        ],
        star: 1
      ]

      scope_with_one = Foxtail::Bundle::Scope.new(bundle, count: 1)
      result = resolver.resolve_expression(expr, scope_with_one)
      expect(result).to eq("many items") # Should fall back to default
    end
  end
end
