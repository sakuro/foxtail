# frozen_string_literal: true

module Fantail
  module Syntax
    class Parser
      module AST
        # Represents parser error annotations with code, arguments, and message
        class Annotation < SyntaxNode
          attr_accessor :code
          attr_accessor :arguments
          attr_accessor :message

          def initialize(code, arguments=[], message="")
            super()
            @code = code
            @arguments = arguments
            @message = message
          end
        end
      end
    end
  end
end
