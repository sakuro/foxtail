# frozen_string_literal: true

require_relative "support/fluent_js"

RSpec.describe "Fluent.js Compatibility" do
  include FluentJsCompatibility::TestHelper

  let(:comparator) { FluentJsCompatibility::AstComparator.new }

  describe "structure fixtures (with spans)" do
    FluentJsCompatibility::FixtureLoader.structure_fixtures.each do |fixture|
      context fixture[:name] do
        it "matches fluent.js AST output" do
          expected_ast = FluentJsCompatibility::FixtureLoader.load_expected_ast(fixture[:json_path])
          ftl_source = FluentJsCompatibility::FixtureLoader.load_ftl_source(fixture[:ftl_path])
          actual_ast = parse_ftl(ftl_source, with_spans: true)

          comparison = comparator.compare(expected_ast, actual_ast)
          status = comparator.determine_status(comparison)

          expect(status).to eq(:perfect_match).or eq(:partial_match)
        end
      end
    end
  end

  describe "reference fixtures (without spans)" do
    FluentJsCompatibility::FixtureLoader.reference_fixtures.each do |fixture|
      context fixture[:name] do
        if FluentJsCompatibility::TestHelper.known_incompatibility?(fixture[:name])
          it "is a known incompatibility", skip: "Known fluent.js incompatibility - intentionally skipped" do
            # Intentionally empty - this test is skipped
          end
        else
          it "matches fluent.js AST output" do
            expected_ast = FluentJsCompatibility::FixtureLoader.load_expected_ast(fixture[:json_path])
            ftl_source = FluentJsCompatibility::FixtureLoader.load_ftl_source(fixture[:ftl_path])
            actual_ast = parse_ftl(ftl_source, with_spans: false)

            process_junk_annotations!(actual_ast)

            comparison = comparator.compare(expected_ast, actual_ast)
            status = comparator.determine_status(comparison)

            expect(status).to eq(:perfect_match).or eq(:partial_match)
          end
        end
      end
    end
  end
end
