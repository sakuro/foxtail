# frozen_string_literal: true

# Compares AST structures for fluent.js compatibility testing
class AstComparator
  # Keys that should be ignored for structural comparison
  SPAN_RELATED_KEYS = %w[span start end].freeze
  private_constant :SPAN_RELATED_KEYS

  # Deep comparison of AST structures
  def compare(expected, actual)
    differences = expected == actual ? [] : find_differences(expected, actual, "root")

    {
      match: expected == actual,
      differences:,
      structural_match: structural_match?(expected, actual),
      span_only_differences: differences.all? {|diff| span_related?(diff) }
    }
  end

  # Determine match status based on comparison results
  def determine_status(comparison)
    return :perfect_match if comparison[:match]
    return :partial_match if comparison[:structural_match] || comparison[:span_only_differences]

    :content_difference
  end

  # Check if ASTs match structurally (ignoring spans and minor details)
  private def structural_match?(expected, actual)
    # Strip spans and compare structure
    expected_structural = strip_spans_and_details(expected)
    actual_structural = strip_spans_and_details(actual)
    expected_structural == actual_structural
  end

  # Check if difference is only span-related
  private def span_related?(diff)
    diff.include?("span") || diff.include?("start") || diff.include?("end")
  end

  # Strip spans and minor details for structural comparison
  private def strip_spans_and_details(obj)
    case obj
    when Hash
      result = {}
      obj.each do |key, value|
        # Skip span-related keys
        next if SPAN_RELATED_KEYS.include?(key)

        result[key] = strip_spans_and_details(value)
      end
      result
    when Array
      obj.map {|item| strip_spans_and_details(item) }
    else
      obj
    end
  end

  # Find detailed differences between AST structures
  private def find_differences(expected, actual, path)
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
