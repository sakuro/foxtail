# frozen_string_literal: true

module Foxtail
  module Function
    # Wraps a numeric value with formatting options
    # The raw value is preserved for selector matching (plural rules)
    class Number < Value
      # Convert FTL/JS style number options to ICU4X options
      # @param options [Hash] FTL/JS style options (camelCase)
      # @return [Hash] ICU4X style options (snake_case with symbols)
      def self.convert_options(options)
        result = {}

        options.each do |key, value|
          case key
          when :style
            result[:style] = value.to_sym
          when :currency
            result[:currency] = value.to_s
          when :minimumIntegerDigits
            result[:minimum_integer_digits] = Integer(value)
          when :minimumFractionDigits
            result[:minimum_fraction_digits] = Integer(value)
          when :maximumFractionDigits
            result[:maximum_fraction_digits] = Integer(value)
          when :useGrouping
            result[:use_grouping] = value
          end
        end

        result
      end

      # Format the number using ICU4X
      # @param bundle [Foxtail::Bundle] The bundle providing locale and context
      # @return [String] The formatted number
      def format(bundle:)
        icu_options = self.class.convert_options(@options)
        ICU4XCache.instance.number_formatter(bundle.locale, **icu_options).format(@value)
      end
    end
  end
end
