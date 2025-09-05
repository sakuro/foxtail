# frozen_string_literal: true

module Foxtail
  class Parser
    module AST
      class NumberLiteral < BaseLiteral
        def parse
          value_str = @value
          
          if value_str.include?(".")
            { value: value_str.to_f }
          else
            { value: value_str.to_i }
          end
        end
      end
    end
  end
end
