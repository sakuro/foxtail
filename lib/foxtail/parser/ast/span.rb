# frozen_string_literal: true

module Foxtail
  class Parser
    module AST
      class Span < BaseNode
        attr_accessor :start, :end

        def initialize(start_pos, end_pos)
          super()
          @start = start_pos
          @end = end_pos
        end
      end
    end
  end
end
