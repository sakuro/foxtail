# frozen_string_literal: true

module Foxtail
  module AST
    # Base class for all AST nodes
    class Node
      def type
        self.class.name.split("::").last
      end
    end

    # Span information for AST nodes
    class Span < Node
      attr_accessor :start
      attr_accessor :end

      def initialize(start_pos, end_pos)
        super()
        @start = start_pos
        @end = end_pos
      end

      def ==(other)
        return false unless other.is_a?(Span)

        @start == other.start && @end == other.end
      end
    end

    # Base class for AST nodes which can have Spans
    class SyntaxNode < Node
      attr_accessor :span

      def initialize
        super
        @span = nil
      end

      def add_span(start_pos, end_pos)
        @span = Span.new(start_pos, end_pos)
      end

      def ==(other)
        return false unless other.class == self.class

        instance_variables.each do |var|
          next if var == :@span

          self_val = instance_variable_get(var)
          other_val = other.instance_variable_get(var)
          return false unless self_val == other_val
        end

        true
      end
    end

    # Identifier for AST nodes
    class Identifier < SyntaxNode
      attr_reader :name

      def initialize(name)
        super()
        @name = name
      end
    end

    # Annotation for Junk nodes
    class Annotation < SyntaxNode
      attr_reader :code
      attr_reader :arguments
      attr_reader :message

      def initialize(code, arguments=[], message=nil)
        super()
        @code = code
        @arguments = arguments
        @message = message || get_error_message(code, arguments)
      end

      private def get_error_message(code, _args)
        "Error #{code}"
      end
    end

    # Junk node for unparseable content
    class Junk < SyntaxNode
      attr_reader :content
      attr_reader :annotations

      def initialize(content)
        super()
        @content = content
        @annotations = []
      end

      def add_annotation(annotation)
        @annotations << annotation
      end
    end

    # Comment node
    class Comment < SyntaxNode
      attr_reader :content

      def initialize(content)
        super()
        @content = content
      end
    end

    # Group comment node
    class GroupComment < Comment
    end

    # Resource comment node
    class ResourceComment < Comment
    end
  end
end
