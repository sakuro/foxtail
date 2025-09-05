# frozen_string_literal: true

module Foxtail
  class Parser
    module AST
      class Annotation < SyntaxNode
        attr_accessor :code, :arguments, :message

        def initialize(code, arguments = [], message = "")
          super()
          @code = code
          @arguments = arguments
          @message = message
        end
      end
    end
  end
end
