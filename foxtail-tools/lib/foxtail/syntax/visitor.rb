# frozen_string_literal: true

module Foxtail
  module Syntax
    # Visitor module for traversing AST nodes
    #
    # Include this module and override the visit_* methods you need.
    # All visit_* methods return nil by default (no-op).
    #
    # @example Collecting message IDs
    #   class MessageIdCollector
    #     include Foxtail::Syntax::Visitor
    #
    #     def initialize
    #       @ids = []
    #     end
    #
    #     attr_reader :ids
    #
    #     def visit_message(node)
    #       @ids << node.id.name
    #       visit_children(node)
    #     end
    #   end
    #
    #   collector = MessageIdCollector.new
    #   resource.accept(collector)
    #   collector.ids # => ["hello", "goodbye", ...]
    module Visitor
      # Container nodes
      def visit_resource(_node) = nil
      def visit_message(_node) = nil
      def visit_term(_node) = nil
      def visit_attribute(_node) = nil
      def visit_pattern(_node) = nil
      def visit_placeable(_node) = nil

      # Expression nodes
      def visit_select_expression(_node) = nil
      def visit_variant(_node) = nil
      def visit_call_arguments(_node) = nil
      def visit_named_argument(_node) = nil

      # Reference nodes
      def visit_message_reference(_node) = nil
      def visit_term_reference(_node) = nil
      def visit_function_reference(_node) = nil
      def visit_variable_reference(_node) = nil

      # Literal nodes
      def visit_string_literal(_node) = nil
      def visit_number_literal(_node) = nil
      def visit_text_element(_node) = nil
      def visit_identifier(_node) = nil

      # Comment nodes
      def visit_comment(_node) = nil
      def visit_group_comment(_node) = nil
      def visit_resource_comment(_node) = nil

      # Error nodes
      def visit_junk(_node) = nil
      def visit_annotation(_node) = nil

      # Metadata nodes
      def visit_span(_node) = nil

      # Helper method to recursively visit all children of a node
      def visit_children(node)
        node.children.each {|child| child&.accept(self) }
      end
    end
  end
end
