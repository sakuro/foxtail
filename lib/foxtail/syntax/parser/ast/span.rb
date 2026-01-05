# frozen_string_literal: true

module Foxtail
  module Syntax
    class Parser
      module AST
        # Represents a source code span with start and end positions
        # Used to track the location of AST nodes in the original source text
        class Span < BaseNode
          attr_accessor :start
          attr_accessor :end

          def initialize(start_pos, end_pos)
            super()
            @start = start_pos
            @end = end_pos
          end
        end
      end
    end
  end
end
