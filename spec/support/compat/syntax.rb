# frozen_string_literal: true

require_relative "base"
require_relative "syntax/ast_comparator"
require_relative "syntax/matchers"

# Compatibility testing support for fluent-syntax
module FluentCompatSyntax
  include FluentCompatBase
  extend FluentCompatBase

  FIXTURES_ROOT = FLUENT_JS_ROOT / "fluent-syntax" / "test"
  private_constant :FIXTURES_ROOT

  STRUCTURE_FIXTURES = FIXTURES_ROOT / "fixtures_structure"
  private_constant :STRUCTURE_FIXTURES

  REFERENCE_FIXTURES = FIXTURES_ROOT / "fixtures_reference"
  private_constant :REFERENCE_FIXTURES

  KNOWN_MISMATCHES = [
    # https://github.com/projectfluent/fluent.js/blob/9a183312d4db035d6002c93e03f0c169a58f3234/fluent-syntax/test/reference_test.js#L24-L28
    {category: :reference, name: "leading_dots"}
  ].freeze
  private_constant :KNOWN_MISMATCHES

  module_function def all_fixtures
    collect_fixtures(
      {json_dir: STRUCTURE_FIXTURES, ftl_dir: STRUCTURE_FIXTURES, category: :structure, with_spans: true},
      {json_dir: REFERENCE_FIXTURES, ftl_dir: REFERENCE_FIXTURES, category: :reference, with_spans: false}
    )
  end

  def parse_ftl(source, with_spans:)
    parser = Foxtail::Syntax::Parser.new(with_spans:)
    resource = parser.parse(source)
    resource.to_h
  end

  def process_junk_annotations!(ast)
    return unless ast["body"].is_a?(Array)

    ast["body"].map! do |entry|
      entry["type"] == "Junk" ? entry.merge("annotations" => []) : entry
    end
  end

  def known_mismatch?(fixture) = KNOWN_MISMATCHES.include?(fixture.slice(:category, :name))
end
