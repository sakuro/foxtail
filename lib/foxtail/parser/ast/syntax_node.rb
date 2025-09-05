# frozen_string_literal: true

module Foxtail
  class Parser
    module AST
      class SyntaxNode < BaseNode
        attr_accessor :span

        def add_span(start_pos, end_pos)
          @span = Span.new(start_pos, end_pos)
        end
      end
    end
  end
end
