# frozen_string_literal: true

require_relative "base"

module Foxtail
  module AST
    # Resource node representing a complete FTL resource
    class Resource < SyntaxNode
      attr_reader :body

      def initialize(body=[])
        super()
        @body = body
      end
    end
  end
end
