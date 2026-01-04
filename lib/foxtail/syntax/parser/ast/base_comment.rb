# frozen_string_literal: true

module Foxtail
  module Syntax
    class Parser
      module AST
        # Base class for all comment types in Fluent syntax
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
end
