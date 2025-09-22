# frozen_string_literal: true

module Foxtail
  module Intl
    # Maps Latin digits (0-9) to digits in different numbering systems
    #
    # This class provides conversion between Latin digits and other
    # numbering system digits based on CLDR numbering system data.
    #
    # @example Converting to Arabic-Indic digits
    #   mapper = DigitMapper.new("arab")
    #   mapper.map("123.45")  # => "١٢٣.٤٥"
    #
    # @example Converting to Thai digits
    #   mapper = DigitMapper.new("thai")
    #   mapper.map("1,234.56")  # => "๑,๒๓๔.๕๖"
    class DigitMapper
      # Latin digits used as the base for conversion
      LATIN_DIGITS = "0123456789"
      private_constant :LATIN_DIGITS

      # Create a new digit mapper for a specific numbering system
      #
      # @param numbering_system [String] The numbering system ID (e.g., "arab", "thai")
      # @param numbering_systems_data [Hash] Optional CLDR numbering systems data
      def initialize(numbering_system, numbering_systems_data=nil)
        @numbering_system = numbering_system
        @numbering_systems_data = numbering_systems_data || load_numbering_systems_data
        @digit_map = build_digit_map
      end

      # Convert a string containing Latin digits to the target numbering system
      #
      # Only numeric digits (0-9) are converted. All other characters
      # (decimal points, thousands separators, currency symbols, etc.)
      # are left unchanged.
      #
      # @param text [String] Text containing Latin digits
      # @return [String] Text with digits converted to target numbering system
      #
      # @example
      #   mapper = DigitMapper.new("arab")
      #   mapper.map("$1,234.56")  # => "$١,٢٣٤.٥٦"
      def map(text)
        return text if @numbering_system == "latn" || @digit_map.nil?

        text.tr(LATIN_DIGITS, @digit_map)
      end

      # Check if the numbering system is supported (has digit mapping)
      #
      # @return [Boolean] true if the numbering system has digit mapping
      def supported?
        !@digit_map.nil?
      end

      # Get the digit mapping string for this numbering system
      #
      # @return [String, nil] The 10-character string of digits, or nil if not supported
      def digits
        @digit_map
      end

      # Build the digit mapping for the numbering system
      #
      # @return [String, nil] 10-character string for tr() mapping, or nil if not numeric
      private def build_digit_map
        system_data = @numbering_systems_data.dig("numbering_systems", @numbering_system)
        return nil unless system_data

        case system_data["type"]
        when "numeric"
          digits = system_data["digits"]
          # Ensure we have exactly 10 characters for 0-9 mapping
          if digits && digits.length >= 10
            # Take first 10 characters (some systems might have more)
            digits[0, 10]
          end
        when "algorithmic"
          # Algorithmic numbering systems like "jpan" require different handling
          # For now, return nil to indicate no simple digit mapping available
          nil
        end
      end

      # Load numbering systems data from CLDR
      #
      # @return [Hash] CLDR numbering systems data
      private def load_numbering_systems_data
        numbering_systems_path = Foxtail.cldr_dir + "numbering_systems.yml"

        unless numbering_systems_path.exist?
          raise Foxtail::CLDR::Repository::DataNotAvailable,
            "Numbering systems data not found. Run 'rake cldr:extract:numbering_systems'"
        end

        require "yaml"
        YAML.load_file(numbering_systems_path)
      end
    end
  end
end
