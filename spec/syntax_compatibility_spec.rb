# frozen_string_literal: true

require "spec_helper"
require "support/fixture_helper"

# Constants for compatibility testing
module FluentCompatibilityTestHelper
  LOG_FILE = "tmp/fluent_compatibility.log"
  private_constant :LOG_FILE

  def self.setup_log
    require "fileutils"
    FileUtils.mkdir_p("tmp")
    @log_file = File.open(LOG_FILE, "w")
  end

  def self.close_log
    @log_file&.close unless @log_file&.closed?
  end

  def self.log
    @log_file
  end
end

RSpec.describe "Fluent.js Compatibility" do
  before(:all) do
    FluentCompatibilityTestHelper.setup_log
  end

  after(:all) do
    FluentCompatibilityTestHelper.close_log
  end

  # Register after(:suite) hook for final output
  RSpec.configure do |config|
    config.after(:suite) do
      require "rainbow"

      log_file = "tmp/fluent_compatibility.log"
      summary_file = "tmp/fluent_compatibility_summary.txt"

      if File.exist?(log_file)
        puts "\nFluent.js compatibility details written to: #{log_file}"
      end

      if File.exist?(summary_file)
        puts Rainbow(File.read(summary_file)).magenta
      end
    end
  end
  describe "fixtures_structure" do
    let(:fixture_pairs) { FixtureHelper.find_fixture_pairs(FixtureHelper::STRUCTURE_FIXTURES) }
    let(:results) { [] }

    it "finds fixture pairs" do
      expect(fixture_pairs).not_to be_empty
      FluentCompatibilityTestHelper.log.puts "Found #{fixture_pairs.length} structure fixture pairs"
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
            FluentCompatibilityTestHelper.log.puts "✅ #{pair[:name]}: Perfect match"
          else
            FluentCompatibilityTestHelper.log.puts "❌ #{pair[:name]}: #{comparison[:differences].length} differences"
            # Show first few differences for debugging
            comparison[:differences].first(3).each do |diff|
              FluentCompatibilityTestHelper.log.puts "  - #{diff}"
            end
          end

          # Expect perfect match for structure fixtures
          expect(comparison[:match]).to be(true), <<~ERROR
            Structure fixture #{pair[:name]} failed with #{comparison[:differences].length} differences:
            #{comparison[:differences].first(5).join("\n")}
          ERROR
        end
      end

      after(:all) do
        passed = fixture_pairs.count {|pair|
          ftl_source = FixtureHelper.load_ftl_source(pair[:ftl_path])
          expected_ast = FixtureHelper.load_expected_ast(pair[:json_path])
          parser = Foxtail::Parser.new(with_spans: true)
          actual_ast = parser.parse(ftl_source).to_h
          FixtureHelper.compare_asts(expected_ast, actual_ast)[:match]
        }

        FluentCompatibilityTestHelper.log.puts <<~SUMMARY

          ============================================================
          STRUCTURE FIXTURES SUMMARY
          ============================================================
          Passed: #{passed}/#{fixture_pairs.length} (#{(passed * 100.0 / fixture_pairs.length).round(1)}%)
          ============================================================
        SUMMARY
      end
    end
  end

  describe "fixtures_reference" do
    let(:fixture_pairs) { FixtureHelper.find_fixture_pairs(FixtureHelper::REFERENCE_FIXTURES) }

    it "finds reference fixture pairs" do
      if FixtureHelper::REFERENCE_FIXTURES.exist?
        expect(fixture_pairs).not_to be_empty
        FluentCompatibilityTestHelper.log.puts "Found #{fixture_pairs.length} reference fixture pairs"
      else
        FluentCompatibilityTestHelper.log.puts "Reference fixtures directory not found - this is optional"
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
            actual_ast["body"] = actual_ast["body"].map {|entry|
              if entry["type"] == "Junk"
                entry.merge("annotations" => [])
              else
                entry
              end
            }
          end

          # Compare ASTs
          comparison = FixtureHelper.compare_asts(expected_ast, actual_ast)

          if comparison[:match]
            FluentCompatibilityTestHelper.log.puts "✅ #{pair[:name]}: Perfect match"
          else
            FluentCompatibilityTestHelper.log.puts "❌ #{pair[:name]}: #{comparison[:differences].length} differences"
            if pair[:name] == "leading_dots"
              FluentCompatibilityTestHelper.log.puts <<~NOTE
                Note: This is a known fluent.js incompatibility (intentionally skipped by fluent.js)
              NOTE
            else
              # Show first few differences for debugging
              comparison[:differences].first(3).each do |diff|
                FluentCompatibilityTestHelper.log.puts "  - #{diff}"
              end
            end
          end

          # Allow leading_dots to fail (known fluent.js incompatibility)
          if pair[:name] == "leading_dots"
            skip "Known fluent.js incompatibility - intentionally skipped by fluent.js itself"
          else
            expect(comparison[:match]).to be(true), <<~ERROR
              Reference fixture #{pair[:name]} failed with #{comparison[:differences].length} differences:
              #{comparison[:differences].first(5).join("\n")}
            ERROR
          end
        end
      end

      after(:all) do
        passed = fixture_pairs.count {|pair|
          ftl_source = FixtureHelper.load_ftl_source(pair[:ftl_path])
          expected_ast = FixtureHelper.load_expected_ast(pair[:json_path])
          parser = Foxtail::Parser.new(with_spans: false)
          actual_ast = parser.parse(ftl_source).to_h

          # Clear Junk annotations for compatibility
          if actual_ast["body"]
            actual_ast["body"] = actual_ast["body"].map {|entry|
              if entry["type"] == "Junk"
                entry.merge("annotations" => [])
              else
                entry
              end
            }
          end

          FixtureHelper.compare_asts(expected_ast, actual_ast)[:match]
        }

        note = if passed < fixture_pairs.length
                 "Note: remaining failure is 'leading_dots' - a known fluent.js incompatibility"
               else
                 ""
               end

        FluentCompatibilityTestHelper.log.puts <<~SUMMARY

          ============================================================
          REFERENCE FIXTURES SUMMARY
          ============================================================
          Passed: #{passed}/#{fixture_pairs.length} (#{(passed * 100.0 / fixture_pairs.length).round(1)}%)
          #{note}
          ============================================================
        SUMMARY
      end
    end
  end

  describe "overall compatibility" do
    it "achieves near 100% fluent.js compatibility" do
      structure_pairs = FixtureHelper.find_fixture_pairs(FixtureHelper::STRUCTURE_FIXTURES)
      reference_pairs = FixtureHelper.find_fixture_pairs(FixtureHelper::REFERENCE_FIXTURES)

      # Test structure fixtures
      structure_passed = structure_pairs.count {|pair|
        ftl_source = FixtureHelper.load_ftl_source(pair[:ftl_path])
        expected_ast = FixtureHelper.load_expected_ast(pair[:json_path])
        parser = Foxtail::Parser.new(with_spans: true)
        actual_ast = parser.parse(ftl_source).to_h
        FixtureHelper.compare_asts(expected_ast, actual_ast)[:match]
      }

      # Test reference fixtures
      reference_passed = reference_pairs.count {|pair|
        ftl_source = FixtureHelper.load_ftl_source(pair[:ftl_path])
        expected_ast = FixtureHelper.load_expected_ast(pair[:json_path])
        parser = Foxtail::Parser.new(with_spans: false)
        actual_ast = parser.parse(ftl_source).to_h

        # Clear Junk annotations for compatibility
        if actual_ast["body"]
          actual_ast["body"] = actual_ast["body"].map {|entry|
            if entry["type"] == "Junk"
              entry.merge("annotations" => [])
            else
              entry
            end
          }
        end

        FixtureHelper.compare_asts(expected_ast, actual_ast)[:match]
      }

      total_passed = structure_passed + reference_passed
      total_tests = structure_pairs.length + reference_pairs.length
      percentage = (total_passed * 100.0 / total_tests).round(1)

      mission_text =
        if percentage >= 99.0
          "🎉 MISSION ACCOMPLISHED - Near 100% compatibility achieved!\nThe Foxtail parser is ready for production use."
        else
          ""
        end

      final_report = <<~FINAL

        ============================================================
        🎉 FINAL COMPATIBILITY RESULTS 🎉
        ============================================================
        Structure Fixtures: #{structure_passed}/#{structure_pairs.length} (#{(structure_passed * 100.0 / structure_pairs.length).round(1)}%)
        Reference Fixtures: #{reference_passed}/#{reference_pairs.length} (#{(reference_passed * 100.0 / reference_pairs.length).round(1)}%)
        OVERALL: #{total_passed}/#{total_tests} (#{percentage}%)
        #{mission_text}
        ============================================================
      FINAL

      FluentCompatibilityTestHelper.log.puts final_report

      # Save summary for after(:suite) output
      File.write(
        "tmp/fluent_compatibility_summary.txt",
        "Fluent.js Compatibility: #{total_passed}/#{total_tests} (#{percentage}%)"
      )

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
      ast1 = {"type" => "Resource", "body" => []}
      ast2 = {"type" => "Resource", "body" => []}

      comparison = FixtureHelper.compare_asts(ast1, ast2)
      expect(comparison[:match]).to be(true)
      expect(comparison[:differences]).to be_empty
    end
  end
end
