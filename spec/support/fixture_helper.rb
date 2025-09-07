# frozen_string_literal: true

require "json"
require "pathname"

module FixtureHelper
  # Path to fluent.js fixtures
  SYNTAX_FIXTURES_ROOT = Pathname.new(__dir__).parent.parent / "fluent.js" / "fluent-syntax" / "test"
  private_constant :SYNTAX_FIXTURES_ROOT

  BUNDLE_FIXTURES_ROOT = Pathname.new(__dir__).parent.parent / "fluent.js" / "fluent-bundle" / "test"
  private_constant :BUNDLE_FIXTURES_ROOT

  # Syntax fixtures (Parser AST testing)
  STRUCTURE_FIXTURES = SYNTAX_FIXTURES_ROOT / "fixtures_structure"
  public_constant :STRUCTURE_FIXTURES

  REFERENCE_FIXTURES = SYNTAX_FIXTURES_ROOT / "fixtures_reference"
  public_constant :REFERENCE_FIXTURES

  # Bundle fixtures (Resource AST testing)
  BUNDLE_STRUCTURE_FIXTURES = BUNDLE_FIXTURES_ROOT / "fixtures_structure"
  private_constant :BUNDLE_STRUCTURE_FIXTURES

  BUNDLE_REFERENCE_FIXTURES = BUNDLE_FIXTURES_ROOT / "fixtures_reference"
  private_constant :BUNDLE_REFERENCE_FIXTURES

  # These fixtures don't have corresponding FTL files in fluent-syntax
  # They are bundle-specific test cases with empty or minimal content
  MISSING_FTL_FIXTURES = %w[
    foo
    section
    section_with_comment
    selector_expression_ends_abruptly
    variant_lists
    variants_indent
  ].freeze
  private_constant :MISSING_FTL_FIXTURES

  # Find all .ftl/.json fixture pairs
  def self.find_fixture_pairs(directory)
    return [] unless directory.exist?

    ftl_files = directory.glob("*.ftl")
    pairs = []

    ftl_files.each do |ftl_path|
      json_path = ftl_path.sub_ext(".json")
      if json_path.exist?
        pairs << {
          name: ftl_path.basename(".ftl").to_s,
          ftl_path:,
          json_path:
        }
      else
        warn "Missing JSON fixture for #{ftl_path.basename}"
      end
    end

    pairs.sort_by {|pair| pair[:name] }
  end

  # Load expected AST from JSON fixture
  def self.load_expected_ast(json_path)
    content = File.read(json_path, encoding: "utf-8")
    JSON.parse(content)
  rescue JSON::ParserError => e
    raise RuntimeError, "Failed to parse JSON fixture #{json_path}: #{e.message}"
  end

  # Load FTL source content
  def self.load_ftl_source(ftl_path)
    File.read(ftl_path, encoding: "utf-8")
  rescue Encoding::InvalidByteSequenceError => e
    raise RuntimeError, "Failed to read FTL fixture #{ftl_path}: #{e.message}"
  end

  # Parse FTL source with Ruby parser
  def self.parse_ftl_with_ruby(source)
    parser = Foxtail::Parser.new
    resource = parser.parse(source)
    resource.to_h
  end

  # Deep comparison of AST structures
  def self.compare_asts(expected, actual)
    {
      match: expected == actual,
      differences: expected == actual ? [] : find_differences(expected, actual, "root")
    }
  end

  # Find detailed differences between AST structures
  def self.find_differences(expected, actual, path)
    differences = []

    case [expected.class, actual.class]
    when [Hash, Hash]
      all_keys = (expected.keys + actual.keys).uniq
      all_keys.each do |key|
        exp_val = expected[key]
        act_val = actual[key]

        if exp_val.nil? && !act_val.nil?
          differences << "#{path}.#{key}: expected nil, got #{act_val.class}(#{act_val.inspect})"
        elsif !exp_val.nil? && act_val.nil?
          differences << "#{path}.#{key}: expected #{exp_val.class}(#{exp_val.inspect}), got nil"
        elsif exp_val != act_val
          differences.concat(find_differences(exp_val, act_val, "#{path}.#{key}"))
        end
      end

    when [Array, Array]
      max_length = [expected.length, actual.length].max
      max_length.times do |i|
        exp_val = expected[i]
        act_val = actual[i]

        if exp_val.nil? && !act_val.nil?
          differences << "#{path}[#{i}]: expected end of array, got #{act_val.class}(#{act_val.inspect})"
        elsif !exp_val.nil? && act_val.nil?
          differences << "#{path}[#{i}]: expected #{exp_val.class}(#{exp_val.inspect}), got end of array"
        elsif exp_val != act_val
          differences.concat(find_differences(exp_val, act_val, "#{path}[#{i}]"))
        end
      end

    else
      if expected != actual
        differences << "#{path}: expected #{expected.class}(#{expected.inspect}), got #{actual.class}(#{actual.inspect})"
      end
    end

    differences
  end

  # Generate compatibility report
  def self.generate_compatibility_report(results)
    total = results.length
    matches = results.count {|result| result[:comparison][:match] }
    percentage = total > 0 ? (Float(matches) / total * 100).round(1) : 0

    report = []
    report << ("=" * 60)
    report << "FLUENT.JS COMPATIBILITY REPORT"
    report << ("=" * 60)
    report << "Perfect matches: #{matches}/#{total} (#{percentage}%)"
    report << ""

    # Group results by status
    perfect_matches = []
    content_differences = []
    parsing_failures = []

    results.each do |result|
      case result[:status]
      when :perfect_match
        perfect_matches << result
      when :content_difference
        content_differences << result
      when :parsing_failure
        parsing_failures << result
      end
    end

    # Report perfect matches
    if perfect_matches.any?
      report << "✅ Perfect matches (#{perfect_matches.length}):"
      perfect_matches.each {|r| report << "  #{r[:name]}" }
      report << ""
    end

    # Report content differences
    if content_differences.any?
      report << "⚠️  Content differences (#{content_differences.length}):"
      content_differences.each do |result|
        report << "  #{result[:name]}: #{result[:comparison][:differences].length} differences"
      end
      report << ""
    end

    # Report parsing failures
    if parsing_failures.any?
      report << "❌ Parsing failures (#{parsing_failures.length}):"
      parsing_failures.each do |result|
        report << "  #{result[:name]}: #{result[:error]}"
      end
      report << ""
    end

    report << ("=" * 60)
    report.join("\n")
  end

  # Find Bundle fixture pairs (FTL from syntax, JSON from bundle)
  def self.find_bundle_fixture_pairs(bundle_json_directory)
    return [] unless bundle_json_directory.exist?

    json_files = bundle_json_directory.glob("*.json")
    pairs = []

    json_files.each do |json_path|
      fixture_name = json_path.basename(".json").to_s

      # Skip known missing fixtures
      if MISSING_FTL_FIXTURES.include?(fixture_name)
        next
      end

      # Determine FTL directory based on bundle directory name
      fixture_type =
        if bundle_json_directory.basename.to_s.include?("structure")
          "fixtures_structure"
        else
          "fixtures_reference"
        end
      ftl_path = SYNTAX_FIXTURES_ROOT / fixture_type / json_path.basename.sub_ext(".ftl")

      if ftl_path.exist?
        pairs << {
          name: fixture_name,
          ftl_path:,
          json_path:
        }
      else
        warn "Missing FTL fixture for #{json_path.basename} (expected at #{ftl_path})"
      end
    end

    pairs.sort_by {|pair| pair[:name] }
  end

  # Load expected Bundle AST from Bundle JSON fixture
  def self.load_expected_bundle_ast(json_path)
    content = File.read(json_path, encoding: "utf-8")
    JSON.parse(content)
  rescue JSON::ParserError => e
    raise RuntimeError, "Failed to parse Bundle JSON fixture #{json_path}: #{e.message}"
  end
end
