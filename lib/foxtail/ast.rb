# frozen_string_literal: true

module Foxtail
  # Base class for all Fluent AST nodes.
  # Ruby equivalent of fluent.js BaseNode
  class BaseNode
    attr_accessor :type

    def initialize
      @type = self.class.name.split("::").last
    end

    # Compare nodes for equality, ignoring specified fields
    def ==(other, ignored_fields = ["span"])
      return false unless other.is_a?(BaseNode)

      this_keys = instance_variables.map { |v| v.to_s.delete("@") }.to_set
      other_keys = other.instance_variables.map { |v| v.to_s.delete("@") }.to_set

      if ignored_fields
        ignored_fields.each do |field|
          this_keys.delete(field)
          other_keys.delete(field)
        end
      end

      return false if this_keys.size != other_keys.size

      this_keys.each do |field_name|
        return false unless other_keys.include?(field_name)

        this_val = instance_variable_get("@#{field_name}")
        other_val = other.instance_variable_get("@#{field_name}")

        return false unless this_val.class == other_val.class

        if this_val.is_a?(Array) && other_val.is_a?(Array)
          return false if this_val.length != other_val.length
          this_val.each_with_index do |item, i|
            return false unless scalars_equal(item, other_val[i], ignored_fields)
          end
        elsif !scalars_equal(this_val, other_val, ignored_fields)
          return false
        end
      end

      true
    end

    # Convert node to hash representation for JSON serialization
    def to_h
      result = {}
      instance_variables.each do |var|
        key = var.to_s.delete("@")
        value = instance_variable_get(var)
        result[key] = serialize_value(value)
      end
      result
    end

    private

    def scalars_equal(this_val, other_val, ignored_fields)
      if this_val.is_a?(BaseNode) && other_val.is_a?(BaseNode)
        this_val == other_val
      else
        this_val == other_val
      end
    end

    def serialize_value(value)
      case value
      when BaseNode
        value.to_h
      when Array
        value.map { |v| serialize_value(v) }
      else
        value
      end
    end
  end

  # Base class for AST nodes which can have Spans
  # Ruby equivalent of fluent.js SyntaxNode
  class SyntaxNode < BaseNode
    attr_accessor :span

    def add_span(start_pos, end_pos)
      @span = Span.new(start_pos, end_pos)
    end
  end

  # Position span information
  class Span < BaseNode
    attr_accessor :start, :end

    def initialize(start_pos, end_pos)
      super()
      @start = start_pos
      @end = end_pos
    end
  end

  # Root AST node
  class Resource < SyntaxNode
    attr_accessor :body

    def initialize(body = [])
      super()
      @body = body
    end
  end

  # Message entry
  class Message < SyntaxNode
    attr_accessor :id, :value, :attributes, :comment

    def initialize(id, value = nil, attributes = [], comment = nil)
      super()
      @id = id
      @value = value
      @attributes = attributes
      @comment = comment
    end
  end

  # Term entry (prefixed with -)
  class Term < SyntaxNode
    attr_accessor :id, :value, :attributes, :comment

    def initialize(id, value, attributes = [], comment = nil)
      super()
      @id = id
      @value = value
      @attributes = attributes
      @comment = comment
    end
  end

  # Pattern containing text and placeables
  class Pattern < SyntaxNode
    attr_accessor :elements

    def initialize(elements)
      super()
      @elements = elements
    end
  end

  # Text content within patterns
  class TextElement < SyntaxNode
    attr_accessor :value

    def initialize(value)
      super()
      @value = value
    end
  end

  # Placeable expression within patterns
  class Placeable < SyntaxNode
    attr_accessor :expression

    def initialize(expression)
      super()
      @expression = expression
    end
  end

  # Identifier for messages, terms, attributes, etc.
  class Identifier < SyntaxNode
    attr_accessor :name

    def initialize(name)
      super()
      @name = name
    end
  end

  # Message/Term attribute
  class Attribute < SyntaxNode
    attr_accessor :id, :value

    def initialize(id, value)
      super()
      @id = id
      @value = value
    end
  end

  # Base class for all literals
  class BaseLiteral < SyntaxNode
    attr_accessor :value

    def initialize(value)
      super()
      # The "value" field contains the exact contents of the literal,
      # character-for-character.
      @value = value
    end

    # Abstract method - subclasses must implement
    def parse
      raise NotImplementedError, "Subclasses must implement parse method"
    end
  end

  # String literal
  class StringLiteral < BaseLiteral
    def parse
      # Backslash backslash, backslash double quote, uHHHH, UHHHHHH.
      known_escapes = /(?:\\\\|\\"|\\u([0-9a-fA-F]{4})|\\U([0-9a-fA-F]{6}))/

      escaped_value = @value.gsub(known_escapes) do |match|
        codepoint4 = $1
        codepoint6 = $2

        case match
        when "\\\\"
          "\\"
        when '\\"'
          '"'
        else
          codepoint = (codepoint4 || codepoint6).to_i(16)
          if codepoint <= 0xd7ff || 0xe000 <= codepoint
            # It's a Unicode scalar value.
            codepoint.chr(Encoding::UTF_8)
          else
            # Escape sequences representing surrogate code points are
            # well-formed but invalid in Fluent. Replace them with U+FFFD
            # REPLACEMENT CHARACTER.
            "\uFFFD"
          end
        end
      end

      { value: escaped_value }
    end
  end

  # Number literal
  class NumberLiteral < BaseLiteral
    def parse
      value_str = @value
      
      if value_str.include?(".")
        { value: value_str.to_f }
      else
        { value: value_str.to_i }
      end
    end
  end

  # Variable reference ($var)
  class VariableReference < SyntaxNode
    attr_accessor :id

    def initialize(id)
      super()
      @id = id
    end
  end

  # Message reference
  class MessageReference < SyntaxNode
    attr_accessor :id, :attribute

    def initialize(id, attribute = nil)
      super()
      @id = id
      @attribute = attribute
    end
  end

  # Term reference (-)
  class TermReference < SyntaxNode
    attr_accessor :id, :attribute, :arguments

    def initialize(id, attribute = nil, arguments = nil)
      super()
      @id = id
      @attribute = attribute
      @arguments = arguments
    end
  end

  # Function call
  class FunctionReference < SyntaxNode
    attr_accessor :id, :arguments

    def initialize(id, arguments = nil)
      super()
      @id = id
      @arguments = arguments
    end
  end

  # Select expression
  class SelectExpression < SyntaxNode
    attr_accessor :selector, :variants

    def initialize(selector, variants)
      super()
      @selector = selector
      @variants = variants
    end
  end

  # Variant within select expressions
  class Variant < SyntaxNode
    attr_accessor :key, :value, :default

    def initialize(key, value, default = false)
      super()
      @key = key
      @value = value
      @default = default
    end
  end

  # Named argument in function calls
  class NamedArgument < SyntaxNode
    attr_accessor :name, :value

    def initialize(name, value)
      super()
      @name = name
      @value = value
    end
  end

  # Argument list for function calls and term references
  class CallArguments < SyntaxNode
    attr_accessor :positional, :named

    def initialize(positional = [], named = [])
      super()
      @positional = positional
      @named = named
    end
  end

  # Base class for comments
  class BaseComment < SyntaxNode
    attr_accessor :content

    def initialize(content)
      super()
      @content = content
    end
  end

  # Regular comment
  class Comment < BaseComment
  end

  # Group comment  
  class GroupComment < BaseComment
  end

  # Resource comment
  class ResourceComment < BaseComment
  end

  # Junk entry (unparseable content)
  class Junk < SyntaxNode
    attr_accessor :content, :annotations

    def initialize(content, annotations = [])
      super()
      @content = content
      @annotations = annotations
    end
  end

  # Annotation for errors
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