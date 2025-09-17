# frozen_string_literal: true

require "fileutils"

RSpec.describe Foxtail::CLDR::Repository::PluralRules do
  describe "#initialize" do
    it "loads rules for supported locale" do
      rules = Foxtail::CLDR::Repository::PluralRules.new(locale("en"))
      expect(rules).to be_instance_of(Foxtail::CLDR::Repository::PluralRules)
    end

    it "raises DataNotAvailable for unsupported locale" do
      expect {
        Foxtail::CLDR::Repository::PluralRules.new(locale("nonexistent"))
      }.to raise_error(Foxtail::CLDR::Repository::DataNotAvailable)
    end
  end

  describe "#select" do
    context "with English locale" do
      let(:rules) { Foxtail::CLDR::Repository::PluralRules.new(locale("en")) }

      it "returns 'one' for 1" do
        expect(rules.select(1)).to eq("one")
      end

      it "returns 'other' for 0, 2-10, etc" do
        [0, 2, 3, 5, 10, 21, 100].each do |n|
          expect(rules.select(n)).to eq("other")
        end
      end
    end

    context "with Russian locale" do
      let(:rules) { Foxtail::CLDR::Repository::PluralRules.new(locale("ru")) }

      it "returns 'one' for 1, 21, 31, etc (ends in 1 but not 11)" do
        [1, 21, 31, 41, 51, 101, 121].each do |n|
          expect(rules.select(n)).to eq("one")
        end
      end

      it "returns 'few' for 2-4, 22-24, etc (ends in 2-4 but not 12-14)" do
        [2, 3, 4, 22, 23, 24, 32, 33, 34].each do |n|
          expect(rules.select(n)).to eq("few")
        end
      end

      it "returns 'many' for 0, 5-20, 25-30, etc" do
        [0, 5, 6, 11, 12, 13, 14, 15, 25, 26, 100].each do |n|
          expect(rules.select(n)).to eq("many")
        end
      end
    end

    context "with Arabic locale" do
      let(:rules) { Foxtail::CLDR::Repository::PluralRules.new(locale("ar")) }

      it "returns 'zero' for 0" do
        expect(rules.select(0)).to eq("zero")
      end

      it "returns 'one' for 1" do
        expect(rules.select(1)).to eq("one")
      end

      it "returns 'two' for 2" do
        expect(rules.select(2)).to eq("two")
      end

      it "returns 'few' for 3-10" do
        (3..10).each do |n|
          expect(rules.select(n)).to eq("few")
        end
      end

      it "returns 'many' for 11-99" do
        [11, 15, 20, 50, 99].each do |n|
          expect(rules.select(n)).to eq("many")
        end
      end

      it "returns 'other' for 100+" do
        [100, 101, 200, 1000].each do |n|
          expect(rules.select(n)).to eq("other")
        end
      end
    end

    context "with Welsh locale" do
      let(:rules) { Foxtail::CLDR::Repository::PluralRules.new(locale("cy")) }

      it "returns correct categories for specific numbers" do
        expect(rules.select(0)).to eq("zero")
        expect(rules.select(1)).to eq("one")
        expect(rules.select(2)).to eq("two")
        expect(rules.select(3)).to eq("few")
        expect(rules.select(6)).to eq("many")
        expect(rules.select(7)).to eq("other")
        expect(rules.select(10)).to eq("other")
      end
    end

    context "with Breton locale (complex rules)" do
      let(:rules) { Foxtail::CLDR::Repository::PluralRules.new(locale("br")) }

      it "returns 'one' for numbers ending in 1 (except 11, 71, 91)" do
        [1, 21, 31, 41, 51, 61, 81, 101].each do |n|
          expect(rules.select(n)).to eq("one")
        end
      end

      it "returns 'other' for excluded 'one' numbers (11, 71, 91)" do
        [11, 71, 91].each do |n|
          expect(rules.select(n)).to eq("other")
        end
      end

      it "returns 'two' for numbers ending in 2 (except 12, 72, 92)" do
        [2, 22, 32, 42, 52, 62, 82, 102].each do |n|
          expect(rules.select(n)).to eq("two")
        end
      end

      it "returns 'other' for excluded 'two' numbers (12, 72, 92)" do
        [12, 72, 92].each do |n|
          expect(rules.select(n)).to eq("other")
        end
      end

      it "returns 'few' for numbers ending in 3-4, 9" do
        [3, 4, 9, 23, 24, 29].each do |n|
          expect(rules.select(n)).to eq("few")
        end
      end

      it "returns 'many' for millions" do
        [1_000_000, 2_000_000, 5_000_000].each do |n|
          expect(rules.select(n)).to eq("many")
        end
      end
    end

    context "with floating point numbers" do
      let(:rules) { Foxtail::CLDR::Repository::PluralRules.new(locale("en")) }

      it "handles float numbers correctly" do
        # CLDR-compliant approach for "en" locale: 1.0 has visible decimal point, so it's "other"
        # Per CLDR spec: @decimal 0.0~1.5 are examples of "other" category for English
        expect(rules.select(1.0)).to eq("other") # v=1 (visible decimal point)
        expect(rules.select(1.5)).to eq("other") # v=1 (has fractional digits)
        expect(rules.select(2.0)).to eq("other") # v=1 (visible decimal point)
      end
    end
  end

  describe "data loading" do
    it "loads data on-demand for each locale" do
      # Use a temporary directory and copy fixture files
      Dir.mktmpdir do |tmpdir|
        test_data_dir = Pathname(tmpdir) + "test_cldr"
        fixture_dir = Pathname(__dir__).parent.parent.parent + "fixtures" + "cldr"

        # Copy fixture files to test directory
        test_data_dir.mkpath
        FileUtils.cp_r(fixture_dir + "parent_locales.yml", test_data_dir) if (fixture_dir + "parent_locales.yml").exist?
        FileUtils.cp_r(fixture_dir + "en", test_data_dir) if (fixture_dir + "en").exist?
        FileUtils.cp_r(fixture_dir + "root", test_data_dir) if (fixture_dir + "root").exist?

        # Initialize resolver with the test data directory
        resolver = Foxtail::CLDR::Repository::Resolver.new(locale("en"), data_dir: test_data_dir)

        # Create PluralRules with custom resolver
        allow(Foxtail::CLDR::Repository::Resolver).to receive(:new)
          .with(locale("en"))
          .and_return(resolver)

        rules = Foxtail::CLDR::Repository::PluralRules.new(locale("en"))
        expect(rules.select(1)).to eq("one")
      end
    end

    it "raises DataNotAvailable for missing locale files" do
      expect {
        Foxtail::CLDR::Repository::PluralRules.new(locale("nonexistent_locale"))
      }.to raise_error(Foxtail::CLDR::Repository::DataNotAvailable)
    end
  end

  describe "operand extraction" do
    let(:rules) { Foxtail::CLDR::Repository::PluralRules.new(locale("en")) }

    # Test internal method through behavior
    it "correctly extracts integer operands" do
      # Test via behavior: English "one" rule is "i = 1 and v = 0"
      # CLDR-compliant: 1.0 has visible fraction digits so it's "other"
      expect(rules.select(1)).to eq("one") # i=1, v=0
      expect(rules.select(1.0)).to eq("other") # i=1, v=1 (visible decimal point)
      expect(rules.select(1.5)).to eq("other") # i=1, v=1 (has visible fraction)
    end
  end

  describe "condition evaluation" do
    let(:rules) { Foxtail::CLDR::Repository::PluralRules.new(locale("ru")) }

    it "handles complex conditions with 'and' and 'or'" do
      # Russian rules test complex boolean logic
      expect(rules.select(1)).to eq("one")   # v = 0 and i % 10 = 1 and i % 100 != 11
      expect(rules.select(11)).to eq("many") # fails i % 100 != 11 condition
      expect(rules.select(2)).to eq("few")   # v = 0 and i % 10 = 2..4 and i % 100 != 12..14
      expect(rules.select(12)).to eq("many") # fails i % 100 != 12..14 condition
    end
  end

  describe "range parsing" do
    let(:rules) { Foxtail::CLDR::Repository::PluralRules.new(locale("ar")) }

    it "handles range expressions like '3..10'" do
      # Arabic "few" rule: n % 100 = 3..10
      (3..10).each do |n|
        expect(rules.select(n)).to eq("few")
      end

      expect(rules.select(2)).to eq("two")   # outside range
      expect(rules.select(11)).to eq("many") # outside range
    end
  end
end
