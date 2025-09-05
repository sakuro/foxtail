# frozen_string_literal: true

module Foxtail
  class Parser
    module AST
      class Junk < SyntaxNode
        attr_accessor :content, :annotations

        def initialize(content, annotations = [])
          super()
          @content = content
          @annotations = annotations
        end
      end
    end
  end
end
