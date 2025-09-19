# frozen_string_literal: true

RSpec.describe Foxtail::CLDR::Repository::TimezoneNames do
  let(:en_locale) { locale("en") }
  let(:ja_locale) { locale("ja") }

  describe "with English locale" do
    subject(:timezone_names) { Foxtail::CLDR::Repository::TimezoneNames.new(en_locale) }

    describe "#zone_name" do
      it "returns short timezone names" do
        expect(timezone_names.zone_name("Pacific/Honolulu", :short, :generic)).to eq("HST")
        expect(timezone_names.zone_name("Pacific/Honolulu", :short, :standard)).to eq("HST")
        expect(timezone_names.zone_name("Pacific/Honolulu", :short, :daylight)).to eq("HDT")
      end

      it "returns long timezone names" do
        expect(timezone_names.zone_name("Etc/UTC", :long, :standard)).to eq("Coordinated Universal Time")
        expect(timezone_names.zone_name("Europe/London", :long, :daylight)).to eq("British Summer Time")
      end

      it "returns nil for non-existent zones" do
        expect(timezone_names.zone_name("Invalid/Timezone", :long, :standard)).to be_nil
      end
    end

    describe "#exemplar_city" do
      it "returns exemplar city names" do
        expect(timezone_names.exemplar_city("Etc/Unknown")).to eq("Unknown City")
      end

      it "returns nil for zones without exemplar cities" do
        expect(timezone_names.exemplar_city("Etc/UTC")).to be_nil
      end
    end

    describe "#timezone_format" do
      it "returns format patterns" do
        expect(timezone_names.timezone_format(:region_format)).to eq("{0} Time")
        expect(timezone_names.timezone_format(:region_format_daylight)).to eq("{0} Daylight Time")
        expect(timezone_names.timezone_format(:region_format_standard)).to eq("{0} Standard Time")
      end

      it "returns nil for non-existent formats" do
        expect(timezone_names.timezone_format(:invalid_format)).to be_nil
      end
    end

    describe "#zone_abbreviation" do
      it "returns short generic name by default" do
        expect(timezone_names.zone_abbreviation("Pacific/Honolulu")).to eq("HST")
      end

      it "returns specific type abbreviation" do
        expect(timezone_names.zone_abbreviation("Pacific/Honolulu", :daylight)).to eq("HDT")
      end
    end

    describe "#zone_full_name" do
      it "returns long name" do
        expect(timezone_names.zone_full_name("Etc/UTC", :standard)).to eq("Coordinated Universal Time")
      end
    end

    describe "#available_zones" do
      it "returns array of zone IDs" do
        zones = timezone_names.available_zones
        expect(zones).to be_an(Array)
        expect(zones).to include("Pacific/Honolulu")
        expect(zones).to include("Etc/UTC")
      end
    end

    describe "#zone_exists?" do
      it "returns true for existing zones" do
        expect(timezone_names.zone_exists?("Pacific/Honolulu")).to be(true)
        expect(timezone_names.zone_exists?("Etc/UTC")).to be(true)
      end

      it "returns false for non-existent zones" do
        expect(timezone_names.zone_exists?("Invalid/Timezone")).to be(false)
      end
    end

    describe "#hour_format" do
      it "returns hour format pattern with ASCII plus and minus signs" do
        expect(timezone_names.hour_format).to eq("+HH:mm;-HH:mm")
      end
    end

    describe "#format_offset" do
      it "formats positive offsets" do
        expect(timezone_names.format_offset(9 * 3600)).to eq("+09:00") # JST
        expect(timezone_names.format_offset((5 * 3600) + (30 * 60))).to eq("+05:30") # IST
      end

      it "formats negative offsets" do
        expect(timezone_names.format_offset(-5 * 3600)).to eq("-05:00")  # EST
        expect(timezone_names.format_offset(-8 * 3600)).to eq("-08:00")  # PST
      end

      it "formats zero offset" do
        expect(timezone_names.format_offset(0)).to eq("+00:00") # UTC
      end
    end
  end

  describe "with French locale" do
    subject(:timezone_names) { Foxtail::CLDR::Repository::TimezoneNames.new(locale("fr")) }

    describe "#hour_format" do
      it "returns hour format pattern with Unicode minus sign U+2212" do
        # French uses Unicode minus sign (U+2212) instead of ASCII hyphen
        expect(timezone_names.hour_format).to eq("+HH:mm;\u{2212}HH:mm")
      end
    end

    describe "#gmt_format" do
      it "returns UTC format for French" do
        expect(timezone_names.gmt_format).to eq("UTC{0}")
      end
    end
  end

  describe "with Japanese locale" do
    subject(:timezone_names) { Foxtail::CLDR::Repository::TimezoneNames.new(ja_locale) }

    describe "#exemplar_city" do
      it "returns localized city names" do
        expect(timezone_names.exemplar_city("Pacific/Honolulu")).to eq("ホノルル")
        expect(timezone_names.exemplar_city("Etc/Unknown")).to eq("地域不明")
      end
    end

    describe "#timezone_format" do
      it "returns Japanese format patterns" do
        expect(timezone_names.timezone_format(:region_format)).to eq("{0}時間")
        expect(timezone_names.timezone_format(:region_format_daylight)).to eq("{0}夏時間")
        expect(timezone_names.timezone_format(:region_format_standard)).to eq("{0}標準時")
        expect(timezone_names.timezone_format(:fallback_format)).to eq("{1}（{0}）")
      end
    end

    describe "#zone_name" do
      it "returns Japanese timezone names when available" do
        expect(timezone_names.zone_name("Etc/UTC", :long, :standard)).to eq("協定世界時")
      end
    end
  end

  describe "with unknown locale" do
    it "raises DataNotAvailable error" do
      expect {
        Foxtail::CLDR::Repository::TimezoneNames.new(locale("unknown"))
      }.to raise_error(Foxtail::CLDR::Repository::DataNotAvailable)
    end
  end
end
