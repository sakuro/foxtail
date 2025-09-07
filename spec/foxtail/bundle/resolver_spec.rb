# frozen_string_literal: true

RSpec.describe Foxtail::Bundle::Resolver do
  let(:bundle) { Foxtail::Bundle.new(locale("en")) }
  let(:resolver) { Foxtail::Bundle::Resolver.new(bundle) }
  let(:scope) { Foxtail::Bundle::Scope.new(bundle, {name: "World", count: 5}) }

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
      pattern = ["Hello, ", {"type" => "var", "name" => "name"}, "!"]
      result = resolver.resolve_pattern(pattern, scope)
      expect(result).to eq("Hello, World!")
    end

    it "resolves single expression patterns" do
      pattern = {"type" => "var", "name" => "name"}
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
      expr = {"type" => "str", "value" => "hello"}
      result = resolver.resolve_expression(expr, scope)
      expect(result).to eq("hello")
    end

    it "resolves number literals" do
      expr = {"type" => "num", "value" => 42.5}
      result = resolver.resolve_expression(expr, scope)
      expect(result).to eq("42.5")
    end

    it "resolves number literals with precision" do
      expr = {"type" => "num", "value" => 42.567, "precision" => 2}
      result = resolver.resolve_expression(expr, scope)
      expect(result).to eq("42.57")
    end

    it "resolves variable references" do
      expr = {"type" => "var", "name" => "name"}
      result = resolver.resolve_expression(expr, scope)
      expect(result).to eq("World")
    end

    it "handles missing variables" do
      expr = {"type" => "var", "name" => "missing"}
      result = resolver.resolve_expression(expr, scope)
      expect(result).to eq("{$missing}")
      expect(scope.errors).to include("Unknown variable: $missing")
    end

    it "handles unknown expression types" do
      expr = {"type" => "unknown", "value" => "test"}
      result = resolver.resolve_expression(expr, scope)
      expect(result).to eq("{unknown}")
      expect(scope.errors).to include("Unknown expression type: unknown")
    end
  end

  describe "#resolve_term_reference" do
    let(:ftl_source) { "-brand = Firefox" }
    let(:resource) { Foxtail::Resource.from_string(ftl_source) }

    before { bundle.add_resource(resource) }

    it "resolves term references" do
      expr = {"type" => "term", "name" => "brand"}
      result = resolver.resolve_expression(expr, scope)
      expect(result).to eq("Firefox")
    end

    it "handles missing terms" do
      expr = {"type" => "term", "name" => "missing"}
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

      expr = {"type" => "term", "name" => "a"}
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
      expr = {"type" => "mesg", "name" => "hello"}
      result = resolver.resolve_expression(expr, scope)
      expect(result).to eq("Hello world")
    end

    it "handles missing messages" do
      expr = {"type" => "mesg", "name" => "missing"}
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
      expr = {"type" => "func", "name" => "TEST", "args" => [{"type" => "str", "value" => "input"}]}
      result = resolver_with_func.resolve_expression(expr, scope)
      expect(result).to eq("Function result: input")
    end

    it "handles missing functions" do
      expr = {"type" => "func", "name" => "MISSING", "args" => []}
      result = resolver.resolve_expression(expr, scope)
      expect(result).to eq("{MISSING()}")
      expect(scope.errors).to include("Unknown function: MISSING")
    end

    it "handles function errors" do
      error_function = ->(*_args, **_options) { raise RuntimeError, "Test error" }
      bundle_with_error = Foxtail::Bundle.new(locale("en"), functions: {"ERROR" => error_function})
      resolver_with_error = Foxtail::Bundle::Resolver.new(bundle_with_error)

      expr = {"type" => "func", "name" => "ERROR", "args" => []}
      result = resolver_with_error.resolve_expression(expr, scope)
      expect(result).to eq("{ERROR()}")
      expect(scope.errors).to include("Function error in ERROR: Test error")
    end

    it "resolves function calls with named arguments" do
      options_function = ->(*args, **options) { "#{args[0]} with options: #{options.inspect}" }
      bundle_with_options = Foxtail::Bundle.new(locale("en"), functions: {"FORMAT" => options_function})
      resolver_with_options = Foxtail::Bundle::Resolver.new(bundle_with_options)

      expr = {
        "type" => "func",
        "name" => "FORMAT",
        "args" => [
          {"type" => "num", "value" => 42.5},
          {"type" => "narg", "name" => "style", "value" => {"type" => "str", "value" => "currency"}},
          {"type" => "narg", "name" => "minimumFractionDigits", "value" => {"type" => "num", "value" => 2.0}}
        ]
      }

      result = resolver_with_options.resolve_expression(expr, scope)
      expect(result).to include("42.5")
      expect(result).to include("style")
      expect(result).to include("currency")
      expect(result).to include("minimumFractionDigits")
      expect(result).to include("2")
    end

    it "resolves NUMBER function calls with named arguments" do
      # Test with actual NUMBER function
      expr = {
        "type" => "func",
        "name" => "NUMBER",
        "args" => [
          {"type" => "num", "value" => 1234.56},
          {"type" => "narg", "name" => "minimumFractionDigits", "value" => {"type" => "num", "value" => 2.0}}
        ]
      }

      result = resolver.resolve_expression(expr, scope)
      expect(result).to eq("1,234.56") # Should format with 2 decimal places (with locale formatting)
    end

    it "resolves DATETIME function calls with named arguments" do
      # Test with actual DATETIME function
      expr = {
        "type" => "func",
        "name" => "DATETIME",
        "args" => [
          {"type" => "var", "name" => "date"},
          {"type" => "narg", "name" => "year", "value" => {"type" => "str", "value" => "numeric"}}
        ]
      }

      test_date = Time.new(2023, 6, 15)
      scope_with_date = Foxtail::Bundle::Scope.new(bundle, {date: test_date})

      result = resolver.resolve_expression(expr, scope_with_date)
      expect(result).to eq("2023") # Should format only the year
    end
  end

  describe "#resolve_select_expression" do
    it "resolves select expressions with number matching" do
      expr = {
        "type" => "select",
        "selector" => {"type" => "var", "name" => "count"},
        "variants" => [
          {"key" => {"type" => "num", "value" => 0}, "value" => "none"},
          {"key" => {"type" => "num", "value" => 5}, "value" => "five"},
          {"key" => {"type" => "str", "value" => "other"}, "value" => "many"}
        ],
        "star" => 2
      }

      result = resolver.resolve_expression(expr, scope)
      expect(result).to eq("five")
    end

    it "uses default variant when no match" do
      expr = {
        "type" => "select",
        "selector" => {"type" => "var", "name" => "count"},
        "variants" => [
          {"key" => {"type" => "num", "value" => 0}, "value" => "none"},
          {"key" => {"type" => "str", "value" => "other"}, "value" => "many"}
        ],
        "star" => 1
      }

      result = resolver.resolve_expression(expr, scope)
      expect(result).to eq("many")
    end

    it "resolves complex variant values" do
      expr = {
        "type" => "select",
        "selector" => {"type" => "var", "name" => "count"},
        "variants" => [
          {
            "key" => {"type" => "num", "value" => 5},
            "value" => ["You have ", {"type" => "var", "name" => "count"}, " items"]
          }
        ],
        "star" => 0
      }

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
      expr = {"type" => "mesg", "name" => "hello", "attr" => "title"}
      result = resolver.resolve_expression(expr, scope)
      expect(result).to eq("Greeting")
    end

    it "resolves term attributes" do
      expr = {"type" => "term", "name" => "brand", "attr" => "version"}
      result = resolver.resolve_expression(expr, scope)
      expect(result).to eq("89.0")
    end

    it "handles missing attributes" do
      expr = {"type" => "mesg", "name" => "hello", "attr" => "missing"}
      result = resolver.resolve_expression(expr, scope)
      expect(result).to eq("{hello.missing}")
      expect(scope.errors).to include("Unknown message attribute: hello.missing")
    end
  end
end
