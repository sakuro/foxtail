# frozen_string_literal: true

require_relative "../support/fluent_js"

RSpec.describe "Fluent.js Compatibility" do
  include FluentJsCompatibility::TestHelper

  FluentJsCompatibility::FixtureLoader.all_fixtures.each do |fixture|
    describe "#{fixture[:category]} fixtures" do
      context fixture[:name] do
        it "matches fluent.js AST output" do
          pending "Known mismatch in fluent.js" if known_mismatch?(fixture)

          expected_ast = FluentJsCompatibility::FixtureLoader.load_expected_ast(fixture[:json_path])
          ftl_source = FluentJsCompatibility::FixtureLoader.load_ftl_source(fixture[:ftl_path])
          actual_ast = parse_ftl(ftl_source, with_spans: fixture[:with_spans])

          process_junk_annotations!(actual_ast) unless fixture[:with_spans]

          expect(actual_ast).to match_ast(expected_ast)
        end
      end
    end
  end
end
