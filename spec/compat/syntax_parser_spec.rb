# frozen_string_literal: true

require_relative "../support/compat/syntax"

FIXTURES_ROOT = FluentCompatBase::FLUENT_JS_ROOT / "fluent-syntax" / "test"
STRUCTURE_FIXTURES = FIXTURES_ROOT / "fixtures_structure"
REFERENCE_FIXTURES = FIXTURES_ROOT / "fixtures_reference"

ALL_FIXTURES = FluentCompatBase.collect_fixtures(
  {json_dir: STRUCTURE_FIXTURES, ftl_dir: STRUCTURE_FIXTURES, category: :structure, with_spans: true},
  {json_dir: REFERENCE_FIXTURES, ftl_dir: REFERENCE_FIXTURES, category: :reference, with_spans: false}
)

RSpec.describe "fluent-syntax Compatibility" do
  include FluentSyntaxCompatibility::TestHelper

  ALL_FIXTURES.each do |fixture|
    describe "#{fixture[:category]} fixtures" do
      context fixture[:name] do
        it "matches fluent-syntax AST output" do
          pending "Known mismatch in fluent-syntax" if known_mismatch?(fixture)

          expected_ast = FluentCompatBase.load_json(fixture[:json_path])
          ftl_source = FluentCompatBase.load_ftl(fixture[:ftl_path])
          actual_ast = parse_ftl(ftl_source, with_spans: fixture[:with_spans])

          process_junk_annotations!(actual_ast) unless fixture[:with_spans]

          expect(actual_ast).to match_ast(expected_ast)
        end
      end
    end
  end
end
