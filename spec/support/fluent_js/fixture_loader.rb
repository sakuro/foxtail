# frozen_string_literal: true

require "json"
require "pathname"

module FluentJsCompatibility
  # Loads fluent.js test fixtures
  class FixtureLoader
    # Path calculation: spec/support/fluent_js/ -> project root -> fluent.js
    PROJECT_ROOT = Pathname(__dir__).parent.parent.parent
    private_constant :PROJECT_ROOT

    SYNTAX_FIXTURES_ROOT = PROJECT_ROOT / "fluent.js" / "fluent-syntax" / "test"
    private_constant :SYNTAX_FIXTURES_ROOT

    STRUCTURE_FIXTURES = SYNTAX_FIXTURES_ROOT / "fixtures_structure"
    private_constant :STRUCTURE_FIXTURES

    REFERENCE_FIXTURES = SYNTAX_FIXTURES_ROOT / "fixtures_reference"
    private_constant :REFERENCE_FIXTURES

    def self.structure_fixtures = find_fixture_pairs(STRUCTURE_FIXTURES, category: :structure, with_spans: true)

    def self.reference_fixtures = find_fixture_pairs(REFERENCE_FIXTURES, category: :reference, with_spans: false)

    def self.all_fixtures = structure_fixtures + reference_fixtures

    def self.load_expected_ast(json_path)
      content = json_path.read(encoding: "utf-8")
      JSON.parse(content)
    rescue JSON::ParserError => e
      raise StandardError, "Failed to parse JSON fixture #{json_path}: #{e.message}"
    end

    def self.load_ftl_source(ftl_path) = ftl_path.read(encoding: "utf-8")

    private_class_method def self.find_fixture_pairs(directory, category:, with_spans:)
      return [] unless directory.exist?

      ftl_files = directory.glob("*.ftl")
      pairs = []

      ftl_files.each do |ftl_path|
        json_path = ftl_path.sub_ext(".json")
        next unless json_path.exist?

        pairs << {
          name: ftl_path.basename(".ftl").to_s,
          ftl_path:,
          json_path:,
          category:,
          with_spans:
        }
      end

      pairs.sort_by {|pair| pair[:name] }
    end
  end
end
