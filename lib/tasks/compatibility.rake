# frozen_string_literal: true

require_relative "../foxtail"
require_relative "../../spec/support/fixture_helper"

namespace :compatibility do
  desc "Run fluent.js compatibility analysis"
  task :analyze do
    puts "🔍 Analyzing fluent.js compatibility..."
    puts

    # Get all structure fixtures
    fixture_pairs = FixtureHelper.find_fixture_pairs(FixtureHelper::STRUCTURE_FIXTURES)
    puts "Found #{fixture_pairs.length} structure fixture pairs"
    puts

    results = []

    fixture_pairs.each_with_index do |pair, index|
      print "\rProcessing: #{index + 1}/#{fixture_pairs.length} (#{pair[:name]})"
      
      begin
        # Load expected AST
        expected_ast = FixtureHelper.load_expected_ast(pair[:json_path])
        
        # Load FTL source
        ftl_source = FixtureHelper.load_ftl_source(pair[:ftl_path])
        
        # Parse with Ruby parser (placeholder for now)
        actual_ast = FixtureHelper.parse_ftl_with_ruby(ftl_source)
        
        # Compare
        comparison = FixtureHelper.compare_asts(expected_ast, actual_ast)
        
        if comparison[:match]
          results << { name: pair[:name], status: :perfect_match, comparison: comparison }
        else
          results << { 
            name: pair[:name], 
            status: :content_difference, 
            comparison: comparison 
          }
        end

      rescue StandardError => e
        results << { name: pair[:name], status: :parsing_failure, error: e.message }
      end
    end

    puts # New line after progress
    puts

    # Generate and display report
    report = FixtureHelper.generate_compatibility_report(results)
    puts report
    puts

    # Save detailed results to file
    save_detailed_report(results, "tmp/compatibility_report.txt")
    puts "📄 Detailed report saved to tmp/compatibility_report.txt"
  end

  desc "Show fixture statistics"
  task :stats do
    puts "📊 Fluent.js Fixture Statistics"
    puts "=" * 40

    structure_pairs = FixtureHelper.find_fixture_pairs(FixtureHelper::STRUCTURE_FIXTURES)
    puts "Structure fixtures: #{structure_pairs.length}"

    reference_pairs = FixtureHelper.find_fixture_pairs(FixtureHelper::REFERENCE_FIXTURES)
    puts "Reference fixtures: #{reference_pairs.length}"
    puts

    # Show some sample fixture names
    puts "Sample structure fixtures:"
    structure_pairs.first(10).each do |pair|
      puts "  - #{pair[:name]}"
    end

    if structure_pairs.length > 10
      puts "  ... and #{structure_pairs.length - 10} more"
    end
    puts
  end

  desc "Validate fixture integrity"
  task :validate do
    puts "🔍 Validating fixture integrity..."

    structure_pairs = FixtureHelper.find_fixture_pairs(FixtureHelper::STRUCTURE_FIXTURES)
    errors = []

    structure_pairs.each do |pair|
      # Check FTL file
      unless pair[:ftl_path].exist?
        errors << "Missing FTL file: #{pair[:ftl_path]}"
        next
      end

      # Check JSON file
      unless pair[:json_path].exist?
        errors << "Missing JSON file: #{pair[:json_path]}"
        next
      end

      # Validate JSON content
      begin
        ast = FixtureHelper.load_expected_ast(pair[:json_path])
        unless ast.is_a?(Hash) && ast["type"] == "Resource"
          errors << "Invalid JSON structure in #{pair[:json_path]}: missing Resource root"
        end
      rescue JSON::ParserError => e
        errors << "Invalid JSON in #{pair[:json_path]}: #{e.message}"
      end

      # Validate FTL content (basic encoding check)
      begin
        FixtureHelper.load_ftl_source(pair[:ftl_path])
      rescue Encoding::InvalidByteSequenceError => e
        errors << "Invalid encoding in #{pair[:ftl_path]}: #{e.message}"
      end
    end

    if errors.empty?
      puts "✅ All fixtures validated successfully!"
      puts "   Structure fixtures: #{structure_pairs.length}"
    else
      puts "❌ Found #{errors.length} fixture errors:"
      errors.each { |error| puts "   #{error}" }
      exit 1
    end
  end

  private

  def save_detailed_report(results, filepath)
    require "fileutils"
    FileUtils.mkdir_p(File.dirname(filepath))

    File.open(filepath, "w") do |file|
      file.puts "Fluent.js Compatibility Report"
      file.puts "Generated: #{Time.now}"
      file.puts "=" * 60
      file.puts

      results.each do |result|
        file.puts "#{result[:name]} - #{result[:status]}"
        
        case result[:status]
        when :content_difference
          file.puts "  Differences:"
          result[:comparison][:differences].each do |diff|
            file.puts "    #{diff}"
          end
        when :parsing_failure
          file.puts "  Error: #{result[:error]}"
        end
        
        file.puts
      end
    end
  end
end

# Default task
desc "Run compatibility analysis"
task :compatibility => "compatibility:analyze"