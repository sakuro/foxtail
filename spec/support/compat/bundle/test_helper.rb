# frozen_string_literal: true

require_relative "../base"

# Helper methods for fluent-bundle compatibility tests
module FluentBundleCompatibility
  SYNTAX_FIXTURES = FluentCompatBase::FLUENT_JS_ROOT / "fluent-syntax" / "test" / "fixtures_structure"
  private_constant :SYNTAX_FIXTURES

  BUNDLE_FIXTURES = FluentCompatBase::FLUENT_JS_ROOT / "fluent-bundle" / "test" / "fixtures_structure"
  private_constant :BUNDLE_FIXTURES

  module_function def all_fixtures
    FluentCompatBase.collect_fixtures({json_dir: BUNDLE_FIXTURES, ftl_dir: SYNTAX_FIXTURES})
  end

  def parse_ftl(source)
    parser = Foxtail::Bundle::Parser.new
    parser.parse(source)
  end

  def convert_to_json(entries)
    ASTConverter.to_json_format(entries)
  end
end
