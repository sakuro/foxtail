# frozen_string_literal: true

module Foxtail
  class Parser
    module AST
      class BaseNode
        attr_accessor :type

        def initialize
          @type = self.class.name.split("::").last
        end

        # Compare nodes for equality, ignoring specified fields
        def ==(other, ignored_fields = ["span"])
          return false unless other.is_a?(BaseNode)

          this_keys = instance_variables.map { |v| v.to_s.delete("@") }.to_set
          other_keys = other.instance_variables.map { |v| v.to_s.delete("@") }.to_set

          if ignored_fields
            ignored_fields.each do |field|
              this_keys.delete(field)
              other_keys.delete(field)
            end
          end

          return false if this_keys.size != other_keys.size

          this_keys.each do |field_name|
            return false unless other_keys.include?(field_name)

            this_val = instance_variable_get("@#{field_name}")
            other_val = other.instance_variable_get("@#{field_name}")

            return false unless this_val.class == other_val.class

            if this_val.is_a?(Array) && other_val.is_a?(Array)
              return false if this_val.length != other_val.length
              this_val.each_with_index do |item, i|
                return false unless scalars_equal(item, other_val[i], ignored_fields)
              end
            elsif !scalars_equal(this_val, other_val, ignored_fields)
              return false
            end
          end

          true
        end

        # Convert node to hash representation for JSON serialization
        def to_h
          result = {}
          instance_variables.each do |var|
            key = var.to_s.delete("@")
            value = instance_variable_get(var)
            result[key] = serialize_value(value)
          end
          result
        end

        private

        def scalars_equal(this_val, other_val, ignored_fields)
          if this_val.is_a?(BaseNode) && other_val.is_a?(BaseNode)
            this_val == other_val
          else
            this_val == other_val
          end
        end

        def serialize_value(value)
          case value
          when BaseNode
            value.to_h
          when Array
            value.map { |v| serialize_value(v) }
          else
            value
          end
        end
      end
    end
  end
end
