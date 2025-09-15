# frozen_string_literal: true

module Foxtail
  module CLDR
    module Formatter
      # Detects the system's local timezone similar to ICU's TimeZone::detectHostTimeZone()
      # This class provides cross-platform timezone detection with fallback mechanisms
      class LocalTimezoneDetector
        # Detected timezone information
        DetectedTimezone = Data.define(:id, :offset_seconds) {
          # Format timezone offset as string in ISO format (e.g., "+09:00", "-05:00")
          # @return [String] the formatted offset string
          def offset_string
            # Format as "+HH:MM" or "-HH:MM"
            hours = offset_seconds / 3600
            minutes = (offset_seconds % 3600) / 60
            sign = offset_seconds >= 0 ? "+" : "-"
            "%s%02d:%02d" % [sign, hours.abs, minutes.abs]
          end

          # Check if this represents an unknown/undetected timezone
          # @return [Boolean] true if timezone is Etc/Unknown
          def unknown?
            id == "Etc/Unknown"
          end
        }

        # Detect system timezone (main entry point)
        def self.detect
          new.detect
        end

        # Detect the local timezone using multiple strategies
        def detect
          timezone_id = detect_timezone_id
          offset_seconds = Time.now.utc_offset

          DetectedTimezone.new(id: timezone_id, offset_seconds:)
        end

        private def detect_timezone_id
          # Strategy 1: Environment variable TZ
          tz_id = detect_from_tz_env
          return tz_id if tz_id

          # Strategy 2: /etc/localtime symlink (Linux/macOS)
          tz_id = detect_from_etc_localtime
          return tz_id if tz_id

          # Strategy 3: /etc/timezone file (Debian/Ubuntu)
          tz_id = detect_from_etc_timezone
          return tz_id if tz_id

          # Strategy 4: systemctl on systemd systems
          tz_id = detect_from_systemctl
          return tz_id if tz_id

          # Strategy 5: macOS specific methods
          if RUBY_PLATFORM.include?("darwin")
            tz_id = detect_from_macos
            return tz_id if tz_id
          end

          # Fallback: Unknown timezone (ICU compatible)
          "Etc/Unknown"
        end

        # Strategy 1: Check TZ environment variable
        private def detect_from_tz_env
          tz = ENV.fetch("TZ", nil)
          return nil unless tz && !tz.empty?

          # Handle various TZ formats
          case tz
          when %r{^:[A-Za-z_/]+}
            # POSIX format ":America/New_York"
            tz[1..]
          when %r{^[A-Za-z_/]+/[A-Za-z_/]+}
            # Direct IANA format "America/New_York"
            tz
          when /^[A-Z]{3,4}$/
            # Abbreviation like "JST", "EST" - not reliable for IANA ID
            nil
          end
        end

        # Strategy 2: Read /etc/localtime symlink
        private def detect_from_etc_localtime
          localtime_path = "/etc/localtime"
          return nil unless File.symlink?(localtime_path)

          begin
            target = File.readlink(localtime_path)

            # Extract timezone ID from paths like:
            # "/usr/share/zoneinfo/Asia/Tokyo" -> "Asia/Tokyo"
            # "../usr/share/zoneinfo/Europe/London" -> "Europe/London"
            match = target.match(%r{(?:usr/share/)?zoneinfo/(.+)$})
            match&.[](1)
          rescue
            # Ignore errors and try next strategy
            nil
          end
        end

        # Strategy 3: Read /etc/timezone file (Debian/Ubuntu)
        private def detect_from_etc_timezone
          timezone_file = "/etc/timezone"
          return nil unless File.readable?(timezone_file)

          begin
            timezone_id = File.read(timezone_file).strip
            return nil if timezone_id.empty?

            # Validate format (basic check for IANA timezone ID)
            timezone_id.match?(%r{^[A-Za-z_/]+/[A-Za-z_/]+$}) ? timezone_id : nil
          rescue
            nil
          end
        end

        # Strategy 4: Use systemctl (systemd systems)
        private def detect_from_systemctl
          return nil unless command_available?("timedatectl")

          begin
            output = %x(timedatectl show --property=Timezone --value 2>/dev/null).strip
            return nil if output.empty? || $?.exitstatus != 0

            # Validate IANA format
            output.match?(%r{^[A-Za-z_/]+/[A-Za-z_/]+$}) ? output : nil
          rescue
            nil
          end
        end

        # Strategy 5: macOS specific detection
        private def detect_from_macos
          # Try systemsetup command
          if command_available?("systemsetup")
            begin
              output = %x(systemsetup -gettimezone 2>/dev/null)
              if $?.exitstatus == 0
                match = output.match(/Time Zone: (.+)$/)
                timezone_id = match&.[](1)&.strip
                return timezone_id if timezone_id&.match?(%r{^[A-Za-z_/]+/[A-Za-z_/]+$})
              end
            rescue
              # Continue to next method
            end
          end

          # Try reading from macOS system preferences
          # /var/db/timezone/zoneinfo contains the current timezone
          zoneinfo_path = "/var/db/timezone/zoneinfo"
          if File.readable?(zoneinfo_path)
            begin
              timezone_id = File.read(zoneinfo_path).strip
              return timezone_id if timezone_id.match?(%r{^[A-Za-z_/]+/[A-Za-z_/]+$})
            rescue
              # Continue
            end
          end

          nil
        end

        # Check if a command is available in PATH
        private def command_available?(command)
          system("which #{command} > /dev/null 2>&1")
        end
      end
    end
  end
end
