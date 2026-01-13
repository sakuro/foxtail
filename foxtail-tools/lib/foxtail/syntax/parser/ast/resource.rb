# frozen_string_literal: true

module Foxtail
  module Syntax
    class Parser
      module AST
        # Represents a Fluent resource containing messages, terms, and comments
        # This is the root node of a parsed Fluent file
        class Resource < SyntaxNode
          attr_accessor :body

          def initialize(body=[])
            super()
            @body = body
          end

          def children = body

          # Iterate over Message entries only
          # @yield [Message] each message entry
          # @return [Enumerator] if no block given
          # @return [self] if block given
          def each_message(&block)
            return enum_for(__method__) unless block

            body.each {|entry| yield(entry) if entry.is_a?(Message) }
            self
          end

          # Iterate over Term entries only
          # @yield [Term] each term entry
          # @return [Enumerator] if no block given
          # @return [self] if block given
          def each_term(&block)
            return enum_for(__method__) unless block

            body.each {|entry| yield(entry) if entry.is_a?(Term) }
            self
          end

          # Iterate over Message and Term entries (excludes comments and junk)
          # @yield [Message, Term] each message or term entry
          # @return [Enumerator] if no block given
          # @return [self] if block given
          def each_entry(&block)
            return enum_for(__method__) unless block

            body.each {|entry| yield(entry) if entry.is_a?(Message) || entry.is_a?(Term) }
            self
          end
        end
      end
    end
  end
end
