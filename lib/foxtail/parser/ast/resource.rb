# frozen_string_literal: true

module Foxtail
  class Parser
    module AST
      class Resource < SyntaxNode
        attr_accessor :body

        def initialize(body = [])
          super()
          @body = body
        end
      end
    end
  end
end
