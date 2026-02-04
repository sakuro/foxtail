# frozen_string_literal: true

module Foxtail
  module Function
    # Wraps a datetime value with formatting options
    # The raw value is preserved for selector matching
    class DateTime < Value
      # Convert FTL/JS style datetime options to ICU4X options
      # @param options [Hash] FTL/JS style options (camelCase)
      # @return [Hash] ICU4X style options (snake_case with symbols)
      def self.convert_options(options)
        result = {}

        options.each do |key, value|
          case key
          when :dateStyle
            result[:date_style] = value.to_sym
          when :timeStyle
            result[:time_style] = value.to_sym
          when :timeZone
            result[:time_zone] = value.to_s
          end
        end

        result
      end

      # Format the datetime using ICU4X
      # @param bundle [Foxtail::Bundle] The bundle providing locale and context
      # @return [String] The formatted datetime
      def format(bundle:)
        icu_options = self.class.convert_options(@options)
        ICU4XCache.instance.datetime_formatter(bundle.locale, **icu_options).format(@value)
      end
    end
  end
end
