# frozen_string_literal: true

module Fantail
  module Syntax
    class Parser
      module AST
        # Base class for all AST nodes in the Fluent parser
        # Provides common functionality for type management and node equality
        class BaseNode
          attr_accessor :type

          def initialize = @type = self.class.name.split("::").last

          # Compare nodes for equality, ignoring span information
          def ==(other)
            return false unless other.is_a?(BaseNode)

            this_keys = instance_variables.to_set {|v| v.to_s.delete("@") }
            other_keys = other.instance_variables.to_set {|v| v.to_s.delete("@") }

            # Always ignore span information in equality comparison
            this_keys.delete("span")
            other_keys.delete("span")

            return false if this_keys.size != other_keys.size

            this_keys.each do |field_name|
              return false unless other_keys.include?(field_name)

              this_val = instance_variable_get("@#{field_name}")
              other_val = other.instance_variable_get("@#{field_name}")

              return false unless this_val.class == other_val.class

              if this_val.is_a?(Array) && other_val.is_a?(Array)
                return false if this_val.length != other_val.length

                this_val.each_with_index do |item, i|
                  return false unless item == other_val[i]
                end
              elsif this_val != other_val
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

          private def serialize_value(value)
            case value
            when BaseNode
              value.to_h
            when Array
              value.map {|v| serialize_value(v) }
            else
              value
            end
          end
        end
      end
    end
  end
end
