# frozen_string_literal: true

module Foxtail
  module Syntax
    # Visitor module for traversing AST nodes
    #
    # Include this module and override the visit_* methods you need.
    # By default, all visit_* methods traverse children automatically.
    # Override a method and omit `super` to stop traversal at that node.
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
    #       super  # continue traversal
    #     end
    #   end
    #
    #   collector = MessageIdCollector.new
    #   resource.accept(collector)
    #   collector.ids # => ["hello", "goodbye", ...]
    module Visitor
      def visit_resource(node) = visit_children(node)
      def visit_message(node) = visit_children(node)
      def visit_term(node) = visit_children(node)
      def visit_attribute(node) = visit_children(node)
      def visit_pattern(node) = visit_children(node)
      def visit_placeable(node) = visit_children(node)
      def visit_select_expression(node) = visit_children(node)
      def visit_variant(node) = visit_children(node)
      def visit_call_arguments(node) = visit_children(node)
      def visit_named_argument(node) = visit_children(node)
      def visit_message_reference(node) = visit_children(node)
      def visit_term_reference(node) = visit_children(node)
      def visit_function_reference(node) = visit_children(node)
      def visit_variable_reference(node) = visit_children(node)
      def visit_string_literal(node) = visit_children(node)
      def visit_number_literal(node) = visit_children(node)
      def visit_text_element(node) = visit_children(node)
      def visit_identifier(node) = visit_children(node)
      def visit_comment(node) = visit_children(node)
      def visit_group_comment(node) = visit_children(node)
      def visit_resource_comment(node) = visit_children(node)
      def visit_junk(node) = visit_children(node)
      def visit_annotation(node) = visit_children(node)
      def visit_span(node) = visit_children(node)

      def visit_children(node)
        node.children.each {|child| child&.accept(self) }
      end
    end
  end
end
