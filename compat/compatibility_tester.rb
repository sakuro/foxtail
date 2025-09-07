# frozen_string_literal: true

require "json"
require "pathname"
require_relative "ast_comparator"

# Executes fluent.js compatibility tests
class CompatibilityTester
  # Path to fluent.js fixtures
  SYNTAX_FIXTURES_ROOT = Pathname.new(__dir__).parent / "fluent.js" / "fluent-syntax" / "test"
  private_constant :SYNTAX_FIXTURES_ROOT
  STRUCTURE_FIXTURES = SYNTAX_FIXTURES_ROOT / "fixtures_structure"
  private_constant :STRUCTURE_FIXTURES
  REFERENCE_FIXTURES = SYNTAX_FIXTURES_ROOT / "fixtures_reference"
  private_constant :REFERENCE_FIXTURES

  # Test result structure
  TestResult = Data.define(:name, :category, :status, :comparison, :error) {
    def success?
      status == :perfect_match
    end

    def partial_success?
      status == :partial_match
    end

    def functional_success?
      success? || partial_success?
    end

    def failure?
      status == :parsing_failure
    end

    def difference?
      status == :content_difference
    end
  }

  # Find all .ftl/.json fixture pairs in directory
  def find_fixture_pairs(directory)
    return [] unless directory.exist?

    ftl_files = directory.glob("*.ftl")
    pairs = []

    ftl_files.each do |ftl_path|
      json_path = ftl_path.sub_ext(".json")
      next unless json_path.exist?

      pairs << {
        name: ftl_path.basename(".ftl").to_s,
        ftl_path:,
        json_path:
      }
    end

    pairs.sort_by {|pair| pair[:name] }
  end

  # Load expected AST from JSON fixture
  def load_expected_ast(json_path)
    content = File.read(json_path, encoding: "utf-8")
    JSON.parse(content)
  rescue JSON::ParserError => e
    raise StandardError, "Failed to parse JSON fixture #{json_path}: #{e.message}"
  end

  # Load FTL source content
  def load_ftl_source(ftl_path)
    File.read(ftl_path, encoding: "utf-8")
  rescue Encoding::InvalidByteSequenceError => e
    raise StandardError, "Failed to read FTL fixture #{ftl_path}: #{e.message}"
  end

  # Parse FTL source with Ruby parser
  def parse_ftl(source, with_spans: false)
    parser = Foxtail::Parser.new(with_spans:)
    resource = parser.parse(source)
    resource.to_h
  end

  # Test structure fixtures (with spans)
  def test_structure_fixtures
    fixture_pairs = find_fixture_pairs(STRUCTURE_FIXTURES)
    results = []

    fixture_pairs.each do |pair|
      expected_ast = load_expected_ast(pair[:json_path])
      ftl_source = load_ftl_source(pair[:ftl_path])
      actual_ast = parse_ftl(ftl_source, with_spans: true)

      comparison = comparator.compare(expected_ast, actual_ast)
      status = comparator.determine_status(comparison)

      results << TestResult.new(
        name: pair[:name],
        category: :structure,
        status:,
        comparison:,
        error: nil
      )
    rescue => e
      results << TestResult.new(
        name: pair[:name],
        category: :structure,
        status: :parsing_failure,
        comparison: nil,
        error: e.message
      )
    end

    results
  end

  # Test reference fixtures (without spans, with Junk annotation processing)
  def test_reference_fixtures
    fixture_pairs = find_fixture_pairs(REFERENCE_FIXTURES)
    results = []

    fixture_pairs.each do |pair|
      # Skip known incompatibility
      if pair[:name] == "leading_dots"
        results << TestResult.new(
          name: pair[:name],
          category: :reference,
          status: :known_incompatibility,
          comparison: nil,
          error: "Known fluent.js incompatibility - intentionally skipped"
        )
        next
      end

      begin
        expected_ast = load_expected_ast(pair[:json_path])
        ftl_source = load_ftl_source(pair[:ftl_path])
        actual_ast = parse_ftl(ftl_source, with_spans: false)

        # Process Junk annotations for reference compatibility
        process_junk_annotations!(actual_ast)

        comparison = comparator.compare(expected_ast, actual_ast)
        status = comparator.determine_status(comparison)

        results << TestResult.new(
          name: pair[:name],
          category: :reference,
          status:,
          comparison:,
          error: nil
        )
      rescue => e
        results << TestResult.new(
          name: pair[:name],
          category: :reference,
          status: :parsing_failure,
          comparison: nil,
          error: e.message
        )
      end
    end

    results
  end

  # Test all fixtures
  def test_all_fixtures
    structure_results = test_structure_fixtures
    reference_results = test_reference_fixtures
    structure_results + reference_results
  end

  # Lazy-initialized AST comparator
  private def comparator
    @comparator ||= AstComparator.new
  end

  # Process Junk annotations for reference fixture compatibility
  private def process_junk_annotations!(ast)
    return unless ast["body"].is_a?(Array)

    ast["body"].map! do |entry|
      if entry["type"] == "Junk"
        entry.merge("annotations" => [])
      else
        entry
      end
    end
  end
end
