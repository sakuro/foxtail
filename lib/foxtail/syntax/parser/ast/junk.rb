# frozen_string_literal: true

module Foxtail
  module Syntax
    class Parser
      module AST
      # Represents unparseable content with associated error annotations
      class Junk < SyntaxNode
        attr_accessor :content
        attr_accessor :annotations

        def initialize(content, annotations=[])
          super()
          @content = content
          @annotations = annotations
        end
      end
    end
  end
end
end
