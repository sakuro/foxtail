# frozen_string_literal: true

require "tempfile"

RSpec.describe Foxtail::CLDR::Formatter::LocalTimezoneDetector do
  let(:detector) { Foxtail::CLDR::Formatter::LocalTimezoneDetector.new }

  describe ".detect" do
    it "returns a DetectedTimezone object" do
      result = Foxtail::CLDR::Formatter::LocalTimezoneDetector.detect
      expect(result).to be_a(Foxtail::CLDR::Formatter::LocalTimezoneDetector::DetectedTimezone)
      expect(result.id).to be_a(String)
      expect(result.offset_seconds).to be_a(Integer)
    end
  end

  describe "#detect" do
    it "detects timezone with valid offset" do
      result = detector.detect

      # Should have a reasonable timezone ID (either IANA format or Etc/Unknown)
      expect(result.id).to match(%r{^([A-Za-z_/]+/[A-Za-z_/]+|Etc/Unknown)$})

      # Offset should match system offset
      expect(result.offset_seconds).to eq(Time.now.utc_offset)
    end
  end

  describe "DetectedTimezone" do
    describe "#offset_string" do
      it "formats positive offset correctly" do
        tz = Foxtail::CLDR::Formatter::LocalTimezoneDetector::DetectedTimezone.new(id: "Asia/Tokyo", offset_seconds: 32400) # +9 hours
        expect(tz.offset_string).to eq("+09:00")
      end

      it "formats negative offset correctly" do
        tz = Foxtail::CLDR::Formatter::LocalTimezoneDetector::DetectedTimezone.new(id: "America/New_York", offset_seconds: -18000) # -5 hours
        expect(tz.offset_string).to eq("-05:00")
      end

      it "formats zero offset correctly" do
        tz = Foxtail::CLDR::Formatter::LocalTimezoneDetector::DetectedTimezone.new(id: "UTC", offset_seconds: 0)
        expect(tz.offset_string).to eq("+00:00")
      end
    end

    describe "#unknown?" do
      it "returns true for Etc/Unknown timezone" do
        tz = Foxtail::CLDR::Formatter::LocalTimezoneDetector::DetectedTimezone.new(id: "Etc/Unknown", offset_seconds: 0)
        expect(tz).to be_unknown
      end

      it "returns false for known timezone" do
        tz = Foxtail::CLDR::Formatter::LocalTimezoneDetector::DetectedTimezone.new(id: "Asia/Tokyo", offset_seconds: 32400)
        expect(tz).not_to be_unknown
      end
    end
  end

  describe "timezone detection strategies" do
    describe "#detect_from_tz_env" do
      it "detects IANA format from TZ environment variable" do
        allow(ENV).to receive(:fetch).with("TZ", nil).and_return("America/New_York")
        expect(detector.__send__(:detect_from_tz_env)).to eq("America/New_York")
      end

      it "handles POSIX format TZ variable" do
        allow(ENV).to receive(:fetch).with("TZ", nil).and_return(":Europe/London")
        expect(detector.__send__(:detect_from_tz_env)).to eq("Europe/London")
      end

      it "ignores abbreviation format" do
        allow(ENV).to receive(:fetch).with("TZ", nil).and_return("JST")
        expect(detector.__send__(:detect_from_tz_env)).to be_nil
      end

      it "ignores empty TZ variable" do
        allow(ENV).to receive(:fetch).with("TZ", nil).and_return("")
        expect(detector.__send__(:detect_from_tz_env)).to be_nil
      end
    end

    describe "#detect_from_etc_localtime" do
      it "extracts timezone ID from symlink target" do
        localtime_path = instance_double(Pathname)
        target_path = instance_double(Pathname)
        allow(Pathname).to receive(:new).with("/etc/localtime").and_return(localtime_path)
        allow(localtime_path).to receive_messages(symlink?: true, readlink: target_path)
        allow(target_path).to receive(:to_s).and_return("/usr/share/zoneinfo/Asia/Tokyo")

        expect(detector.__send__(:detect_from_etc_localtime)).to eq("Asia/Tokyo")
      end

      it "handles relative symlink paths" do
        localtime_path = instance_double(Pathname)
        target_path = instance_double(Pathname)
        allow(Pathname).to receive(:new).with("/etc/localtime").and_return(localtime_path)
        allow(localtime_path).to receive_messages(symlink?: true, readlink: target_path)
        allow(target_path).to receive(:to_s).and_return("../usr/share/zoneinfo/Europe/London")

        expect(detector.__send__(:detect_from_etc_localtime)).to eq("Europe/London")
      end

      it "returns nil if not a symlink" do
        localtime_path = instance_double(Pathname)
        allow(Pathname).to receive(:new).with("/etc/localtime").and_return(localtime_path)
        allow(localtime_path).to receive(:symlink?).and_return(false)

        expect(detector.__send__(:detect_from_etc_localtime)).to be_nil
      end

      it "returns nil on read error" do
        localtime_path = instance_double(Pathname)
        allow(Pathname).to receive(:new).with("/etc/localtime").and_return(localtime_path)
        allow(localtime_path).to receive(:symlink?).and_return(true)
        allow(localtime_path).to receive(:readlink).and_raise(Errno::ENOENT)

        expect(detector.__send__(:detect_from_etc_localtime)).to be_nil
      end
    end

    describe "#detect_from_etc_timezone" do
      it "reads timezone ID from file" do
        timezone_file = instance_double(Pathname)
        allow(Pathname).to receive(:new).with("/etc/timezone").and_return(timezone_file)
        allow(timezone_file).to receive_messages(readable?: true, read: "Europe/London\n")

        expect(detector.__send__(:detect_from_etc_timezone)).to eq("Europe/London")
      end

      it "returns nil for invalid format" do
        timezone_file = instance_double(Pathname)
        allow(Pathname).to receive(:new).with("/etc/timezone").and_return(timezone_file)
        allow(timezone_file).to receive_messages(readable?: true, read: "InvalidFormat")

        expect(detector.__send__(:detect_from_etc_timezone)).to be_nil
      end

      it "returns nil if file not readable" do
        timezone_file = instance_double(Pathname)
        allow(Pathname).to receive(:new).with("/etc/timezone").and_return(timezone_file)
        allow(timezone_file).to receive(:readable?).and_return(false)

        expect(detector.__send__(:detect_from_etc_timezone)).to be_nil
      end
    end
  end

  describe "#command_available?" do
    it "returns true for existing commands" do
      # Most systems should have 'echo'
      expect(detector.__send__(:command_available?, "echo")).to be true
    end

    it "returns false for non-existent commands" do
      expect(detector.__send__(:command_available?, "this_command_does_not_exist_12345")).to be false
    end
  end
end
