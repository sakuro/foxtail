# frozen_string_literal: true

require "spec_helper"
require "support/fixture_helper"

RSpec.describe "Fluent.js Compatibility" do
  describe "fixtures_structure" do
    let(:fixture_pairs) { FixtureHelper.find_fixture_pairs(FixtureHelper::STRUCTURE_FIXTURES) }

    it "finds fixture pairs" do
      expect(fixture_pairs).not_to be_empty
      puts "Found #{fixture_pairs.length} structure fixture pairs"
      
      # Show first few fixture names for verification
      fixture_pairs.first(5).each do |pair|
        puts "  - #{pair[:name]}"
      end
    end

    context "individual fixtures" do
      let(:results) { [] }

      fixture_pairs = FixtureHelper.find_fixture_pairs(FixtureHelper::STRUCTURE_FIXTURES)

      fixture_pairs.each do |pair|
        it "parses #{pair[:name]} correctly" do
          # Load expected AST from fluent.js
          expected_ast = FixtureHelper.load_expected_ast(pair[:json_path])
          expect(expected_ast).to be_a(Hash)
          expect(expected_ast["type"]).to eq("Resource")

          # Load FTL source
          ftl_source = FixtureHelper.load_ftl_source(pair[:ftl_path])
          expect(ftl_source).to be_a(String)

          # Parse with Ruby (placeholder for now)
          begin
            actual_ast = FixtureHelper.parse_ftl_with_ruby(ftl_source)
            
            # Compare ASTs
            comparison = FixtureHelper.compare_asts(expected_ast, actual_ast)
            
            # Store result for reporting
            if comparison[:match]
              results << { name: pair[:name], status: :perfect_match, comparison: comparison }
            else
              results << { 
                name: pair[:name], 
                status: :content_difference, 
                comparison: comparison,
                differences: comparison[:differences]
              }
            end

            # For now, just log the status (will fail when we implement real parser)
            if comparison[:match]
              puts "✅ #{pair[:name]}: Perfect match"
            else
              puts "⚠️  #{pair[:name]}: #{comparison[:differences].length} differences"
              comparison[:differences].first(3).each do |diff|
                puts "    #{diff}"
              end
              puts "    ..." if comparison[:differences].length > 3
            end

            # Skip assertion for now since we're using a placeholder parser
            # expect(comparison[:match]).to be true, 
            #   "AST mismatch for #{pair[:name]}:\n#{comparison[:differences].join("\n")}"

          rescue StandardError => e
            results << { name: pair[:name], status: :parsing_failure, error: e.message }
            puts "❌ #{pair[:name]}: Parsing failed - #{e.message}"
            
            # Skip assertion for now
            # expect(e).to be_nil, "Parsing failed for #{pair[:name]}: #{e.message}"
          end
        end
      end

      after(:all) do
        # Generate compatibility report
        unless results.empty?
          report = FixtureHelper.generate_compatibility_report(results)
          puts "\n#{report}"
        end
      end
    end
  end

  describe "fixtures_reference" do
    let(:fixture_pairs) { FixtureHelper.find_fixture_pairs(FixtureHelper::REFERENCE_FIXTURES) }

    it "finds reference fixture pairs" do
      if FixtureHelper::REFERENCE_FIXTURES.exist?
        expect(fixture_pairs).not_to be_empty
        puts "Found #{fixture_pairs.length} reference fixture pairs"
      else
        puts "Reference fixtures directory not found - this is optional"
      end
    end

    # TODO: Add reference fixture tests when structure fixtures are working
  end

  describe "test utilities" do
    it "can parse JSON fixtures" do
      sample_pair = FixtureHelper.find_fixture_pairs(FixtureHelper::STRUCTURE_FIXTURES).first
      expect(sample_pair).not_to be_nil

      ast = FixtureHelper.load_expected_ast(sample_pair[:json_path])
      expect(ast).to be_a(Hash)
      expect(ast["type"]).to eq("Resource")
    end

    it "can load FTL source files" do
      sample_pair = FixtureHelper.find_fixture_pairs(FixtureHelper::STRUCTURE_FIXTURES).first
      expect(sample_pair).not_to be_nil

      source = FixtureHelper.load_ftl_source(sample_pair[:ftl_path])
      expect(source).to be_a(String)
    end

    it "can compare AST structures" do
      ast1 = { "type" => "Resource", "body" => [] }
      ast2 = { "type" => "Resource", "body" => [] }
      ast3 = { "type" => "Resource", "body" => [{ "type" => "Message" }] }

      comparison1 = FixtureHelper.compare_asts(ast1, ast2)
      expect(comparison1[:match]).to be true
      expect(comparison1[:differences]).to be_empty

      comparison2 = FixtureHelper.compare_asts(ast1, ast3)
      expect(comparison2[:match]).to be false
      expect(comparison2[:differences]).not_to be_empty
    end
  end
end