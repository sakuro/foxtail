# frozen_string_literal: true

require "fileutils"

RSpec.describe Foxtail::CLDR::Repository::DateTimeFormats do
  describe "#initialize" do
    it "loads formats for supported locale" do
      formats = Foxtail::CLDR::Repository::DateTimeFormats.new(locale("en"))
      expect(formats).to be_instance_of(Foxtail::CLDR::Repository::DateTimeFormats)
    end

    it "raises DataNotAvailable for unsupported locale" do
      expect {
        Foxtail::CLDR::Repository::DateTimeFormats.new(locale("nonexistent"))
      }.to raise_error(Foxtail::CLDR::Repository::DataNotAvailable)
    end
  end

  describe "#month_name" do
    context "with English locale" do
      let(:formats) { Foxtail::CLDR::Repository::DateTimeFormats.new(locale("en")) }

      it "returns full month names" do
        expect(formats.month_name(1, "wide")).to eq("January")
        expect(formats.month_name(6, "wide")).to eq("June")
        expect(formats.month_name(12, "wide")).to eq("December")
      end

      it "returns abbreviated month names" do
        expect(formats.month_name(1, "abbreviated")).to eq("Jan")
        expect(formats.month_name(6, "abbreviated")).to eq("Jun")
        expect(formats.month_name(12, "abbreviated")).to eq("Dec")
      end

      it "returns narrow month names" do
        expect(formats.month_name(1, "narrow")).to eq("J")
        expect(formats.month_name(6, "narrow")).to eq("J")
        expect(formats.month_name(12, "narrow")).to eq("D")
      end

      it "handles standalone context" do
        expect(formats.month_name(1, "wide", "stand-alone")).to eq("January")
      end

      it "returns string for invalid month number" do
        expect(formats.month_name(0, "wide")).to eq("0")
        expect(formats.month_name(13, "wide")).to eq("13")
      end
    end

    context "with Japanese locale" do
      let(:formats) { Foxtail::CLDR::Repository::DateTimeFormats.new(locale("ja")) }

      it "returns month names with 月" do
        expect(formats.month_name(1, "wide")).to eq("1月")
        expect(formats.month_name(12, "wide")).to eq("12月")
      end
    end
  end

  describe "#weekday_name" do
    context "with English locale" do
      let(:formats) { Foxtail::CLDR::Repository::DateTimeFormats.new(locale("en")) }

      it "returns full weekday names" do
        expect(formats.weekday_name("sun", "wide")).to eq("Sunday")
        expect(formats.weekday_name("mon", "wide")).to eq("Monday")
        expect(formats.weekday_name("sat", "wide")).to eq("Saturday")
      end

      it "returns abbreviated weekday names" do
        expect(formats.weekday_name("sun", "abbreviated")).to eq("Sun")
        expect(formats.weekday_name("mon", "abbreviated")).to eq("Mon")
        expect(formats.weekday_name("sat", "abbreviated")).to eq("Sat")
      end

      it "returns narrow weekday names" do
        expect(formats.weekday_name("sun", "narrow")).to eq("S")
        expect(formats.weekday_name("mon", "narrow")).to eq("M")
        expect(formats.weekday_name("fri", "narrow")).to eq("F")
      end

      it "returns string for invalid weekday key" do
        expect(formats.weekday_name("invalid", "wide")).to eq("invalid")
        expect(formats.weekday_name("xyz", "wide")).to eq("xyz")
      end
    end

    context "with Japanese locale" do
      let(:formats) { Foxtail::CLDR::Repository::DateTimeFormats.new(locale("ja")) }

      it "returns weekday names with 曜日" do
        expect(formats.weekday_name("sun", "wide")).to eq("日曜日")
        expect(formats.weekday_name("mon", "wide")).to eq("月曜日")
        expect(formats.weekday_name("sat", "wide")).to eq("土曜日")
      end

      it "returns abbreviated weekday names" do
        expect(formats.weekday_name("sun", "abbreviated")).to eq("日")
        expect(formats.weekday_name("mon", "abbreviated")).to eq("月")
        expect(formats.weekday_name("sat", "abbreviated")).to eq("土")
      end
    end
  end

  describe "#day_period" do
    context "with English locale" do
      let(:formats) { Foxtail::CLDR::Repository::DateTimeFormats.new(locale("en")) }

      it "returns AM/PM for standard periods" do
        expect(formats.day_period(9, "wide")).to eq("AM")
        expect(formats.day_period(15, "wide")).to eq("PM")
      end

      it "returns abbreviated periods" do
        expect(formats.day_period(9, "abbreviated")).to eq("AM")
        expect(formats.day_period(15, "abbreviated")).to eq("PM")
      end

      it "returns narrow periods" do
        expect(formats.day_period(9, "narrow")).to eq("AM")
        expect(formats.day_period(15, "narrow")).to eq("PM")
      end

      it "handles extended day periods" do
        # Some locales have morning, afternoon, evening, night
        period = formats.day_period(6, "wide")
        expect(period).to eq("AM")
      end
    end

    context "with Japanese locale" do
      let(:formats) { Foxtail::CLDR::Repository::DateTimeFormats.new(locale("ja")) }

      it "returns Japanese AM/PM" do
        expect(formats.day_period(9, "wide")).to eq("AM")
        expect(formats.day_period(15, "wide")).to eq("PM")
      end
    end
  end

  describe "#date_pattern" do
    context "with English locale" do
      let(:formats) { Foxtail::CLDR::Repository::DateTimeFormats.new(locale("en")) }

      it "returns date patterns for different styles" do
        expect(formats.date_pattern("full")).to eq("EEEE, MMMM d, y")
        expect(formats.date_pattern("long")).to eq("MMMM d, y")
        expect(formats.date_pattern("medium")).to eq("MMM d, y")
        expect(formats.date_pattern("short")).to eq("M/d/yy")
      end
    end

    context "with Japanese locale" do
      let(:formats) { Foxtail::CLDR::Repository::DateTimeFormats.new(locale("ja")) }

      it "returns Japanese date patterns" do
        expect(formats.date_pattern("full")).to eq("y年M月d日EEEE")
        expect(formats.date_pattern("long")).to eq("y年M月d日")
        expect(formats.date_pattern("medium")).to eq("y/MM/dd")
        expect(formats.date_pattern("short")).to eq("y/MM/dd")
      end
    end
  end

  describe "#time_pattern" do
    context "with English locale" do
      let(:formats) { Foxtail::CLDR::Repository::DateTimeFormats.new(locale("en")) }

      it "returns time patterns for different styles" do
        expect(formats.time_pattern("full")).to eq("h:mm:ss a zzzz")
        expect(formats.time_pattern("long")).to eq("h:mm:ss a z")
        expect(formats.time_pattern("medium")).to eq("h:mm:ss a")
        expect(formats.time_pattern("short")).to eq("h:mm a")
      end

      it "returns full and long time patterns with seconds" do
        expect(formats.time_pattern("full")).to eq("h:mm:ss a zzzz")
        expect(formats.time_pattern("long")).to eq("h:mm:ss a z")
      end
    end
  end

  describe "#available_format" do
    context "with English locale" do
      let(:formats) { Foxtail::CLDR::Repository::DateTimeFormats.new(locale("en")) }

      it "returns available format patterns" do
        expect(formats.available_format("yMMMd")).to eq("MMM d, y")
        expect(formats.available_format("Hm")).to eq("HH:mm")
      end

      it "returns nil for unknown skeleton" do
        expect(formats.available_format("xyz")).to be_nil
      end
    end
  end

  describe "#datetime_pattern" do
    context "with English locale" do
      let(:formats) { Foxtail::CLDR::Repository::DateTimeFormats.new(locale("en")) }

      it "combines date and time patterns" do
        pattern = formats.datetime_pattern("medium", "short")
        expect(pattern).to eq("MMM d, y, h:mm a")
      end

      it "handles full date and time combination" do
        pattern = formats.datetime_pattern("full", "full")
        expect(pattern).to eq("EEEE, MMMM d, y 'at' h:mm:ss a zzzz")
      end

      it "handles short combinations" do
        pattern = formats.datetime_pattern("short", "short")
        expect(pattern).to eq("M/d/yy, h:mm a")
      end

      it "handles nil styles with defaults" do
        pattern = formats.datetime_pattern(nil, nil)
        expect(pattern).to be_a(String)
        expect(pattern).not_to be_empty
      end
    end

    context "with Japanese locale" do
      let(:formats) { Foxtail::CLDR::Repository::DateTimeFormats.new(locale("ja")) }

      it "combines date and time patterns in Japanese order" do
        pattern = formats.datetime_pattern("full", "full")
        expect(pattern).to eq("y年M月d日EEEE H時mm分ss秒 zzzz")
      end
    end
  end

  describe "edge cases" do
    let(:formats) { Foxtail::CLDR::Repository::DateTimeFormats.new(locale("en")) }

    it "handles invalid width gracefully" do
      expect(formats.month_name(1, "invalid")).to eq("1")
    end

    it "handles invalid context gracefully" do
      expect(formats.month_name(1, "wide", "invalid")).to eq("1")
    end

    it "handles nil parameters" do
      expect(formats.month_name(nil, "wide")).to eq("")
      expect(formats.weekday_name(nil, "wide")).to eq("")
      expect { formats.day_period(nil, "wide") }.to raise_error(NoMethodError)
    end
  end
end
