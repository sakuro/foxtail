# frozen_string_literal: true

module Foxtail
  class Parser
    module AST
      # Base class for AST nodes that can have span information
      # Extends BaseNode with source position tracking capabilities
      class SyntaxNode < BaseNode
        attr_accessor :span

        # Add span information to this syntax node
        # @param start_pos [Integer] Starting position in the source
        # @param end_pos [Integer] Ending position in the source
        def add_span(start_pos, end_pos)
          @span = Span.new(start_pos, end_pos)
        end
      end
    end
  end
end
