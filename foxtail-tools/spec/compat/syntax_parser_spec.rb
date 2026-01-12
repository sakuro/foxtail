# frozen_string_literal: true

require_relative "../../../spec/support/compat/syntax"

RSpec.describe "fluent-syntax Compatibility" do
  include FluentCompatSyntax

  FluentCompatSyntax.all_fixtures.each do |fixture|
    describe "#{fixture[:category]} fixtures" do
      context fixture[:name] do
        it "matches fluent-syntax AST output" do
          pending "Known mismatch in fluent-syntax" if known_mismatch?(fixture)

          expected_ast = load_json(fixture[:json_path])
          ftl_source = load_ftl(fixture[:ftl_path])
          actual_ast = parse_ftl(ftl_source, with_spans: fixture[:with_spans])

          process_junk_annotations!(actual_ast) unless fixture[:with_spans]

          expect(actual_ast).to match_ast(expected_ast)
        end
      end
    end
  end
end
