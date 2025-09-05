# frozen_string_literal: true

module Foxtail
  class Parser
    module AST
      class BaseComment < SyntaxNode
        attr_accessor :content

        def initialize(content)
          super()
          @content = content
        end
      end
    end
  end
end
