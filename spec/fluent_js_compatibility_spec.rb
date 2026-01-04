# frozen_string_literal: true

require_relative "support/fluent_js"

RSpec.describe "Fluent.js Compatibility" do
  include FluentJsCompatibility::TestHelper

  describe "structure fixtures (with spans)" do
    FluentJsCompatibility::FixtureLoader.structure_fixtures.each do |fixture|
      context fixture[:name] do
        it "matches fluent.js AST output" do
          expected_ast = FluentJsCompatibility::FixtureLoader.load_expected_ast(fixture[:json_path])
          ftl_source = FluentJsCompatibility::FixtureLoader.load_ftl_source(fixture[:ftl_path])
          actual_ast = parse_ftl(ftl_source, with_spans: true)

          expect(actual_ast).to match_ast(expected_ast)
        end
      end
    end
  end

  describe "reference fixtures (without spans)" do
    FluentJsCompatibility::FixtureLoader.reference_fixtures.each do |fixture|
      context fixture[:name] do
        it "matches fluent.js AST output" do
          pending "Known fluent.js incompatibility" if known_incompatibility?(fixture[:name])

          expected_ast = FluentJsCompatibility::FixtureLoader.load_expected_ast(fixture[:json_path])
          ftl_source = FluentJsCompatibility::FixtureLoader.load_ftl_source(fixture[:ftl_path])
          actual_ast = parse_ftl(ftl_source, with_spans: false)

          process_junk_annotations!(actual_ast)

          expect(actual_ast).to match_ast(expected_ast)
        end
      end
    end
  end
end
