# frozen_string_literal: true

module Foxtail
  # Built-in formatting functions for FTL
  # Uses ICU4X for number and datetime formatting
  module Function
    # Default functions available to all bundles
    # @return [Hash{String => #call}] Function name to callable object mapping
    def self.defaults
      {
        "NUMBER" => ->(value, **options) {
          # Unwrap value and merge options from nested function calls (like fluent.js)
          raw_value, existing_options = unwrap_value(value)
          unwrapped_options = unwrap_options(options)
          Number[raw_value, existing_options.merge(unwrapped_options)]
        },
        "DATETIME" => ->(value, **options) {
          # Unwrap value and merge options from nested function calls (like fluent.js)
          raw_value, existing_options = unwrap_value(value)
          unwrapped_options = unwrap_options(options)
          DateTime[raw_value, existing_options.merge(unwrapped_options)]
        }
      }
    end

    # Unwrap a Function::Value to get raw value and options
    # @param value [Object] the value to unwrap
    # @return [Array(Object, Hash)] the raw value and options
    def self.unwrap_value(value)
      if value.is_a?(Value)
        [value.value, value.options]
      else
        [value, {}]
      end
    end

    # Unwrap option values that may be Function::Value instances
    # @param options [Hash] the options hash
    # @return [Hash] options with unwrapped values
    def self.unwrap_options(options)
      options.transform_values do |v|
        v.is_a?(Value) ? v.value : v
      end
    end
  end
end
