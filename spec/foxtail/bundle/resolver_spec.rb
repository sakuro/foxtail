# frozen_string_literal: true

RSpec.describe Foxtail::Bundle::Resolver do
  let(:bundle) { Foxtail::Bundle.new(locale("en")) }
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
      pattern = ["Hello, ", Foxtail::Bundle::AST.var("name"), "!"]
      result = resolver.resolve_pattern(pattern, scope)
      expect(result).to eq("Hello, World!")
    end

    it "resolves single expression patterns" do
      pattern = Foxtail::Bundle::AST.var("name")
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
      expr = Foxtail::Bundle::AST.str("hello")
      result = resolver.resolve_expression(expr, scope)
      expect(result).to eq("hello")
    end

    it "resolves number literals" do
      expr = Foxtail::Bundle::AST.num(42.5)
      result = resolver.resolve_expression(expr, scope)
      expect(result).to eq(42.5)
    end

    it "resolves number literals with precision" do
      expr = Foxtail::Bundle::AST.num(42.567, precision: 2)
      result = resolver.resolve_expression(expr, scope)
      expect(result).to eq(42.567)
    end

    it "resolves variable references" do
      expr = Foxtail::Bundle::AST.var("name")
      result = resolver.resolve_expression(expr, scope)
      expect(result).to eq("World")
    end

    it "handles missing variables" do
      expr = Foxtail::Bundle::AST.var("missing")
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
      expr = Foxtail::Bundle::AST.term("brand")
      result = resolver.resolve_expression(expr, scope)
      expect(result).to eq("Firefox")
    end

    it "handles missing terms" do
      expr = Foxtail::Bundle::AST.term("missing")
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

      expr = Foxtail::Bundle::AST.term("a")
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
      expr = Foxtail::Bundle::AST.mesg("hello")
      result = resolver.resolve_expression(expr, scope)
      expect(result).to eq("Hello world")
    end

    it "handles missing messages" do
      expr = Foxtail::Bundle::AST.mesg("missing")
      result = resolver.resolve_expression(expr, scope)
      expect(result).to eq("{missing}")
      expect(scope.errors).to include("Unknown message: missing")
    end
  end

  describe "#resolve_function_call" do
    let(:test_function) { ->(*args, **_options) { "Function result: #{args[0]}" } }
    let(:bundle_with_func) { Foxtail::Bundle.new(locale("en"), functions: {"TEST" => test_function}) }
    let(:resolver_with_func) { Foxtail::Bundle::Resolver.new(bundle_with_func) }

    it "resolves function calls" do
      expr = Foxtail::Bundle::AST.func("TEST", args: [Foxtail::Bundle::AST.str("input")])
      result = resolver_with_func.resolve_expression(expr, scope)
      expect(result).to eq("Function result: input")
    end

    it "handles missing functions" do
      expr = Foxtail::Bundle::AST.func("MISSING", args: [])
      result = resolver.resolve_expression(expr, scope)
      expect(result).to eq("{MISSING()}")
      expect(scope.errors).to include("Unknown function: MISSING")
    end

    it "handles function errors" do
      error_function = ->(*_args, **_options) { raise RuntimeError, "Test error" }
      bundle_with_error = Foxtail::Bundle.new(locale("en"), functions: {"ERROR" => error_function})
      resolver_with_error = Foxtail::Bundle::Resolver.new(bundle_with_error)

      expr = Foxtail::Bundle::AST.func("ERROR", args: [])
      result = resolver_with_error.resolve_expression(expr, scope)
      expect(result).to eq("{ERROR()}")
      expect(scope.errors).to include("Function error in ERROR: Test error")
    end

    it "resolves function calls with named arguments" do
      options_function = ->(*args, **options) { "#{args[0]} with options: #{options.inspect}" }
      bundle_with_options = Foxtail::Bundle.new(locale("en"), functions: {"FORMAT" => options_function})
      resolver_with_options = Foxtail::Bundle::Resolver.new(bundle_with_options)

      expr = Foxtail::Bundle::AST.func("FORMAT", args: [
        Foxtail::Bundle::AST.num(42.5),
        Foxtail::Bundle::AST.narg("style", Foxtail::Bundle::AST.str("currency")),
        Foxtail::Bundle::AST.narg("minimumFractionDigits", Foxtail::Bundle::AST.num(2.0))
      ])

      result = resolver_with_options.resolve_expression(expr, scope)
      expect(result).to include("42.5")
      expect(result).to include("style")
      expect(result).to include("currency")
      expect(result).to include("minimumFractionDigits")
      expect(result).to include("2")
    end

    it "resolves NUMBER function calls with named arguments" do
      # Test with actual NUMBER function
      expr = Foxtail::Bundle::AST.func("NUMBER", args: [
        Foxtail::Bundle::AST.num(1234.56),
        Foxtail::Bundle::AST.narg("minimumFractionDigits", Foxtail::Bundle::AST.num(2.0))
      ])

      result = resolver.resolve_expression(expr, scope)
      expect(result).to eq("1,234.56") # Should format with 2 decimal places (with locale formatting)
    end

    it "resolves DATETIME function calls with named arguments" do
      skip "ICU4X requires date_style or time_style; component-only formatting (year: numeric) is not supported"
      # Test with actual DATETIME function
      expr = Foxtail::Bundle::AST.func("DATETIME", args: [
        Foxtail::Bundle::AST.var("date"),
        Foxtail::Bundle::AST.narg("year", Foxtail::Bundle::AST.str("numeric"))
      ])

      test_date = Time.new(2023, 6, 15)
      scope_with_date = Foxtail::Bundle::Scope.new(bundle, date: test_date)

      result = resolver.resolve_expression(expr, scope_with_date)
      expect(result).to eq("2023") # Should format only the year
    end
  end

  describe "#resolve_select_expression" do
    it "resolves select expressions with number matching" do
      expr = Foxtail::Bundle::AST.select(
        Foxtail::Bundle::AST.var("count"),
        [
          Foxtail::Bundle::AST.variant(Foxtail::Bundle::AST.num(0), "none"),
          Foxtail::Bundle::AST.variant(Foxtail::Bundle::AST.num(5), "five"),
          Foxtail::Bundle::AST.variant(Foxtail::Bundle::AST.str("other"), "many")
        ],
        star: 2
      )

      result = resolver.resolve_expression(expr, scope)
      expect(result).to eq("five")
    end

    it "uses default variant when no match" do
      expr = Foxtail::Bundle::AST.select(
        Foxtail::Bundle::AST.var("count"),
        [
          Foxtail::Bundle::AST.variant(Foxtail::Bundle::AST.num(0), "none"),
          Foxtail::Bundle::AST.variant(Foxtail::Bundle::AST.str("other"), "many")
        ],
        star: 1
      )

      result = resolver.resolve_expression(expr, scope)
      expect(result).to eq("many")
    end

    it "resolves complex variant values" do
      expr = Foxtail::Bundle::AST.select(
        Foxtail::Bundle::AST.var("count"),
        [
          Foxtail::Bundle::AST.variant(
            Foxtail::Bundle::AST.num(5),
            ["You have ", Foxtail::Bundle::AST.var("count"), " items"]
          )
        ],
        star: 0
      )

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
      expr = Foxtail::Bundle::AST.mesg("hello", attr: "title")
      result = resolver.resolve_expression(expr, scope)
      expect(result).to eq("Greeting")
    end

    it "resolves term attributes" do
      expr = Foxtail::Bundle::AST.term("brand", attr: "version")
      result = resolver.resolve_expression(expr, scope)
      expect(result).to eq("89.0")
    end

    it "handles missing attributes" do
      expr = Foxtail::Bundle::AST.mesg("hello", attr: "missing")
      result = resolver.resolve_expression(expr, scope)
      expect(result).to eq("{hello.missing}")
      expect(scope.errors).to include("Unknown message attribute: hello.missing")
    end
  end

  describe "plural category matching" do
    it "matches plural categories using ICU4X plural rules" do
      # Test English plural rules (1 is "one", others are "other")
      expr = Foxtail::Bundle::AST.select(
        Foxtail::Bundle::AST.var("count"),
        [
          Foxtail::Bundle::AST.variant(Foxtail::Bundle::AST.str("one"), "one item"),
          Foxtail::Bundle::AST.variant(Foxtail::Bundle::AST.str("other"), "many items")
        ],
        star: 1
      )

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
      expr = Foxtail::Bundle::AST.select(
        Foxtail::Bundle::AST.var("count"),
        [
          Foxtail::Bundle::AST.variant(Foxtail::Bundle::AST.num(0), "no items"),
          Foxtail::Bundle::AST.variant(Foxtail::Bundle::AST.str("one"), "one item"),
          Foxtail::Bundle::AST.variant(Foxtail::Bundle::AST.str("other"), "many items")
        ],
        star: 2
      )

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

      expr = Foxtail::Bundle::AST.select(
        Foxtail::Bundle::AST.var("count"),
        [
          Foxtail::Bundle::AST.variant(Foxtail::Bundle::AST.str("one"), "one item"),
          Foxtail::Bundle::AST.variant(Foxtail::Bundle::AST.str("other"), "many items")
        ],
        star: 1
      )

      scope_with_one = Foxtail::Bundle::Scope.new(bundle, count: 1)
      result = resolver.resolve_expression(expr, scope_with_one)
      expect(result).to eq("many items") # Should fall back to default
    end
  end
end
