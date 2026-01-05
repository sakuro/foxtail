# frozen_string_literal: true

require "json"
require "pathname"

module FluentBundleCompatibility
  # Loads fluent-bundle test fixtures
  class FixtureLoader
    PROJECT_ROOT = Pathname(__dir__).parent.parent.parent
    private_constant :PROJECT_ROOT

    SYNTAX_FIXTURES = PROJECT_ROOT / "fluent.js" / "fluent-syntax" / "test" / "fixtures_structure"
    private_constant :SYNTAX_FIXTURES

    BUNDLE_FIXTURES = PROJECT_ROOT / "fluent.js" / "fluent-bundle" / "test" / "fixtures_structure"
    private_constant :BUNDLE_FIXTURES

    def self.all_fixtures = find_fixture_pairs

    def self.load_expected_json(json_path)
      content = json_path.read(encoding: "utf-8")
      JSON.parse(content)
    rescue JSON::ParserError => e
      raise StandardError, "Failed to parse JSON fixture #{json_path}: #{e.message}"
    end

    def self.load_ftl_source(ftl_path) = ftl_path.read(encoding: "utf-8")

    private_class_method def self.find_fixture_pairs
      return [] unless BUNDLE_FIXTURES.exist?

      json_files = BUNDLE_FIXTURES.glob("*.json")
      pairs = []

      json_files.each do |json_path|
        ftl_path = SYNTAX_FIXTURES / json_path.basename.sub_ext(".ftl")
        next unless ftl_path.exist?

        pairs << {
          name: json_path.basename(".json").to_s,
          ftl_path:,
          json_path:
        }
      end

      pairs.sort_by {|pair| pair[:name] }
    end
  end
end
