# frozen_string_literal: true

module FluentJsCompatibility
  # Compares AST structures for fluent.js compatibility testing
  class AstComparator
    # Find detailed differences between AST structures (for debugging)
    def find_differences(expected, actual, path="root")
      differences = []

      case [expected.class, actual.class]
      when [Hash, Hash]
        all_keys = (expected.keys + actual.keys).uniq
        all_keys.each do |key|
          exp_val = expected[key]
          act_val = actual[key]

          if exp_val.nil? && !act_val.nil?
            differences << "#{path}.#{key}: expected nil, got #{act_val.class}(#{act_val.inspect})"
          elsif !exp_val.nil? && act_val.nil?
            differences << "#{path}.#{key}: expected #{exp_val.class}(#{exp_val.inspect}), got nil"
          elsif exp_val != act_val
            differences.concat(find_differences(exp_val, act_val, "#{path}.#{key}"))
          end
        end

      when [Array, Array]
        max_length = [expected.length, actual.length].max
        max_length.times do |i|
          exp_val = expected[i]
          act_val = actual[i]

          if exp_val.nil? && !act_val.nil?
            differences << "#{path}[#{i}]: expected end of array, got #{act_val.class}(#{act_val.inspect})"
          elsif !exp_val.nil? && act_val.nil?
            differences << "#{path}[#{i}]: expected #{exp_val.class}(#{exp_val.inspect}), got end of array"
          elsif exp_val != act_val
            differences.concat(find_differences(exp_val, act_val, "#{path}[#{i}]"))
          end
        end

      else
        if expected != actual
          differences << "#{path}: expected #{expected.class}(#{expected.inspect}), got #{actual.class}(#{actual.inspect})"
        end
      end

      differences
    end
  end
end
