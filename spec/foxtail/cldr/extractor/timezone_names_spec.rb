# frozen_string_literal: true

require "spec_helper"

RSpec.describe Foxtail::CLDR::Extractor::TimezoneNames, type: :extractor do
  subject(:extractor) do
    Foxtail::CLDR::Extractor::TimezoneNames.new(source_dir:, output_dir:)
  end

  describe "draft status filtering" do
    before do
      setup_extractor_fixture(%w[test_timezone.xml])
      setup_parent_locales_fixture
    end

    it "excludes draft='unconfirmed' timezone names" do
      extractor.extract_locale("timezone")

      output_file = output_dir + "timezone" + "timezone_names.yml"
      expect(output_file).to exist

      data = YAML.load_file(output_file)

      # America_Eastern with draft="unconfirmed" should be excluded
      eastern = data.dig("timezone_names", "metazones", "America_Eastern")
      expect(eastern).to be_nil

      # America/New_York zone with draft="unconfirmed" should be excluded from short names
      ny_zone = data.dig("timezone_names", "zones", "America/New_York", "short")
      expect(ny_zone).to be_nil
    end

    it "includes draft='contributed' timezone names" do
      extractor.extract_locale("timezone")

      output_file = output_dir + "timezone" + "timezone_names.yml"
      data = YAML.load_file(output_file)

      # America_Pacific with draft="contributed" should be included
      pacific = data.dig("timezone_names", "metazones", "America_Pacific", "short")
      expect(pacific).to eq({
        "generic" => "PT",
        "standard" => "PST",
        "daylight" => "PDT"
      })
    end

    it "includes draft='provisional' timezone names" do
      extractor.extract_locale("timezone")

      output_file = output_dir + "timezone" + "timezone_names.yml"
      data = YAML.load_file(output_file)

      # Test_Provisional with draft="provisional" should be included
      provisional = data.dig("timezone_names", "metazones", "Test_Provisional", "short")
      expect(provisional).to eq({
        "generic" => "TZ",
        "standard" => "TZS",
        "daylight" => "TZD"
      })
    end

    it "includes timezone names without draft attribute" do
      extractor.extract_locale("timezone")

      output_file = output_dir + "timezone" + "timezone_names.yml"
      data = YAML.load_file(output_file)

      # Europe_London without draft attribute should be included
      london = data.dig("timezone_names", "metazones", "Europe_London", "short")
      expect(london).to eq({
        "generic" => "GMT",
        "standard" => "GMT",
        "daylight" => "BST"
      })

      # Europe/London zone without draft attribute should be included
      london_zone = data.dig("timezone_names", "zones", "Europe/London", "short")
      expect(london_zone).to eq({
        "generic" => "GMT",
        "standard" => "GMT",
        "daylight" => "BST"
      })
    end
  end

  describe "Unicode character preservation" do
    before do
      setup_extractor_fixture(%w[test_timezone_unicode.xml])
      setup_parent_locales_fixture
    end

    it "preserves Unicode minus sign (U+2212) in hour format" do
      extractor.extract_locale("timezone_unicode")

      output_file = output_dir + "timezone_unicode" + "timezone_names.yml"
      expect(output_file).to exist

      data = YAML.load_file(output_file)

      hour_format = data.dig("timezone_names", "formats", "hour_format")
      expect(hour_format).to eq("+HH:mm;\u{2212}HH:mm")

      # Verify it's Unicode minus (U+2212) not ASCII hyphen (U+002D)
      negative_part = hour_format.split(";")[1]
      expect(negative_part[0].ord).to eq(0x2212)
      expect(negative_part[0].ord).not_to eq(0x002D)
    end

    it "preserves other timezone format patterns" do
      extractor.extract_locale("timezone_unicode")

      output_file = output_dir + "timezone_unicode" + "timezone_names.yml"
      data = YAML.load_file(output_file)

      formats = data.dig("timezone_names", "formats")
      expect(formats["gmt_format"]).to eq("UTC{0}")
      expect(formats["region_format"]).to eq("heure : {0}")
      expect(formats["region_format_daylight"]).to eq("{0} (heure d'été)")
      expect(formats["region_format_standard"]).to eq("{0} (heure standard)")
    end
  end
end
