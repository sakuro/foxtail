# frozen_string_literal: true

require "spec_helper"
require "support/fixture_helper"

RSpec.describe "Fluent.js Compatibility" do
  describe "fixtures_structure" do
    let(:fixture_pairs) { FixtureHelper.find_fixture_pairs(FixtureHelper::STRUCTURE_FIXTURES) }
    let(:results) { [] }

    it "finds fixture pairs" do
      expect(fixture_pairs).not_to be_empty
      puts "Found #{fixture_pairs.length} structure fixture pairs"
    end

    context "individual fixtures" do
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

          # Parse with Ruby parser (structure fixtures need spans)
          parser = Foxtail::Parser.new(with_spans: true)
          actual_ast = parser.parse(ftl_source).to_h
          
          # Compare ASTs
          comparison = FixtureHelper.compare_asts(expected_ast, actual_ast)
          
          if comparison[:match]
            puts "✅ #{pair[:name]}: Perfect match"
          else
            puts "❌ #{pair[:name]}: #{comparison[:differences].length} differences"
            # Show first few differences for debugging
            comparison[:differences].first(3).each do |diff|
              puts "  - #{diff}"
            end
          end

          # Expect perfect match for structure fixtures
          expect(comparison[:match]).to be(true), 
            "Structure fixture #{pair[:name]} failed with #{comparison[:differences].length} differences:\n" +
            comparison[:differences].first(5).join("\n")
        end
      end

      after(:all) do
        passed = fixture_pairs.count do |pair|
          ftl_source = FixtureHelper.load_ftl_source(pair[:ftl_path])
          expected_ast = FixtureHelper.load_expected_ast(pair[:json_path])
          parser = Foxtail::Parser.new(with_spans: true)
          actual_ast = parser.parse(ftl_source).to_h
          FixtureHelper.compare_asts(expected_ast, actual_ast)[:match]
        end
        
        puts "\n" + "="*60
        puts "STRUCTURE FIXTURES SUMMARY"  
        puts "="*60
        puts "Passed: #{passed}/#{fixture_pairs.length} (#{(passed * 100.0 / fixture_pairs.length).round(1)}%)"
        puts "="*60
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

    context "individual fixtures" do
      fixture_pairs = FixtureHelper.find_fixture_pairs(FixtureHelper::REFERENCE_FIXTURES)

      fixture_pairs.each do |pair|
        it "parses #{pair[:name]} correctly" do
          # Load expected AST from fluent.js
          expected_ast = FixtureHelper.load_expected_ast(pair[:json_path])
          expect(expected_ast).to be_a(Hash)
          expect(expected_ast["type"]).to eq("Resource")

          # Load FTL source
          ftl_source = FixtureHelper.load_ftl_source(pair[:ftl_path])
          expect(ftl_source).to be_a(String)

          # Parse with Ruby parser (reference fixtures don't need spans)
          parser = Foxtail::Parser.new(with_spans: false)
          actual_ast = parser.parse(ftl_source).to_h
          
          # Reference tests ignore Junk annotations like fluent.js does
          if actual_ast["body"]
            actual_ast["body"] = actual_ast["body"].map do |entry|
              if entry["type"] == "Junk"
                entry.merge("annotations" => [])
              else
                entry
              end
            end
          end
          
          # Compare ASTs
          comparison = FixtureHelper.compare_asts(expected_ast, actual_ast)
          
          if comparison[:match]
            puts "✅ #{pair[:name]}: Perfect match"
          else
            puts "❌ #{pair[:name]}: #{comparison[:differences].length} differences"
            if pair[:name] == "leading_dots"
              puts "  Note: This is a known fluent.js incompatibility (intentionally skipped by fluent.js)"
            else
              # Show first few differences for debugging
              comparison[:differences].first(3).each do |diff|
                puts "  - #{diff}"
              end
            end
          end

          # Allow leading_dots to fail (known fluent.js incompatibility)
          if pair[:name] == "leading_dots"
            pending "Known fluent.js incompatibility - intentionally skipped by fluent.js itself"
          else
            expect(comparison[:match]).to be(true), 
              "Reference fixture #{pair[:name]} failed with #{comparison[:differences].length} differences:\n" +
              comparison[:differences].first(5).join("\n")
          end
        end
      end

      after(:all) do
        passed = fixture_pairs.count do |pair|
          ftl_source = FixtureHelper.load_ftl_source(pair[:ftl_path])
          expected_ast = FixtureHelper.load_expected_ast(pair[:json_path])
          parser = Foxtail::Parser.new(with_spans: false)
          actual_ast = parser.parse(ftl_source).to_h
          
          # Clear Junk annotations for compatibility
          if actual_ast["body"]
            actual_ast["body"] = actual_ast["body"].map do |entry|
              if entry["type"] == "Junk"
                entry.merge("annotations" => [])
              else
                entry
              end
            end
          end
          
          FixtureHelper.compare_asts(expected_ast, actual_ast)[:match]
        end
        
        puts "\n" + "="*60
        puts "REFERENCE FIXTURES SUMMARY"  
        puts "="*60
        puts "Passed: #{passed}/#{fixture_pairs.length} (#{(passed * 100.0 / fixture_pairs.length).round(1)}%)"
        if passed < fixture_pairs.length
          puts "Note: remaining failure is 'leading_dots' - a known fluent.js incompatibility"
        end
        puts "="*60
      end
    end
  end

  describe "overall compatibility" do
    it "achieves near 100% fluent.js compatibility" do
      structure_pairs = FixtureHelper.find_fixture_pairs(FixtureHelper::STRUCTURE_FIXTURES)
      reference_pairs = FixtureHelper.find_fixture_pairs(FixtureHelper::REFERENCE_FIXTURES)
      
      # Test structure fixtures
      structure_passed = structure_pairs.count do |pair|
        ftl_source = FixtureHelper.load_ftl_source(pair[:ftl_path])
        expected_ast = FixtureHelper.load_expected_ast(pair[:json_path])
        parser = Foxtail::Parser.new(with_spans: true)
        actual_ast = parser.parse(ftl_source).to_h
        FixtureHelper.compare_asts(expected_ast, actual_ast)[:match]
      end

      # Test reference fixtures
      reference_passed = reference_pairs.count do |pair|
        ftl_source = FixtureHelper.load_ftl_source(pair[:ftl_path])
        expected_ast = FixtureHelper.load_expected_ast(pair[:json_path])
        parser = Foxtail::Parser.new(with_spans: false)
        actual_ast = parser.parse(ftl_source).to_h
        
        # Clear Junk annotations for compatibility
        if actual_ast["body"]
          actual_ast["body"] = actual_ast["body"].map do |entry|
            if entry["type"] == "Junk"
              entry.merge("annotations" => [])
            else
              entry
            end
          end
        end
        
        FixtureHelper.compare_asts(expected_ast, actual_ast)[:match]
      end

      total_passed = structure_passed + reference_passed
      total_tests = structure_pairs.length + reference_pairs.length
      percentage = (total_passed * 100.0 / total_tests).round(1)

      puts "\n" + "="*60
      puts "🎉 FINAL COMPATIBILITY RESULTS 🎉"
      puts "="*60
      puts "Structure Fixtures: #{structure_passed}/#{structure_pairs.length} (#{(structure_passed * 100.0 / structure_pairs.length).round(1)}%)"
      puts "Reference Fixtures: #{reference_passed}/#{reference_pairs.length} (#{(reference_passed * 100.0 / reference_pairs.length).round(1)}%)"
      puts "OVERALL: #{total_passed}/#{total_tests} (#{percentage}%)"
      
      if percentage >= 99.0
        puts "🎉 MISSION ACCOMPLISHED - Near 100% compatibility achieved!"
        puts "The Foxtail parser is ready for production use."
      end
      puts "="*60

      # Expect near-perfect compatibility (allowing for the known leading_dots issue)
      expect(percentage).to be >= 99.0
    end
  end

  describe "test utilities" do
    it "can parse JSON fixtures" do
      sample_pair = FixtureHelper.find_fixture_pairs(FixtureHelper::STRUCTURE_FIXTURES).first
      expect(sample_pair).not_to be_nil

      expected_ast = FixtureHelper.load_expected_ast(sample_pair[:json_path])
      expect(expected_ast).to be_a(Hash)
      expect(expected_ast["type"]).to eq("Resource")
    end

    it "can load FTL source files" do
      sample_pair = FixtureHelper.find_fixture_pairs(FixtureHelper::STRUCTURE_FIXTURES).first
      expect(sample_pair).not_to be_nil

      ftl_source = FixtureHelper.load_ftl_source(sample_pair[:ftl_path])
      expect(ftl_source).to be_a(String)
      expect(ftl_source.length).to be > 0
    end

    it "can compare AST structures" do
      # Test with identical structures
      ast1 = { "type" => "Resource", "body" => [] }
      ast2 = { "type" => "Resource", "body" => [] }
      
      comparison = FixtureHelper.compare_asts(ast1, ast2)
      expect(comparison[:match]).to be(true)
      expect(comparison[:differences]).to be_empty
    end
  end
end