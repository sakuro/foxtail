# frozen_string_literal: true

# Example 01: Prefix Message IDs
#
# This example demonstrates:
# - Parsing FTL into the syntax AST
# - Renaming message IDs with a "msg-" prefix
# - Updating message references in place
#
# Prints the transformed FTL to stdout.

require "foxtail-tools"

PREFIX = "msg-"

source = <<~FTL
  # App strings
  title = Welcome, { $name }!
  subtitle = { title } is ready.
  msg-footer = Thanks for visiting.
FTL
parser = Foxtail::Syntax::Parser.new
resource = parser.parse(source)

renames = {}

resource.body.each do |entry|
  next unless entry.is_a?(Foxtail::Syntax::Parser::AST::Message)

  id = entry.id
  next if id.nil? || id.name.start_with?(PREFIX)

  new_name = "#{PREFIX}#{id.name}"
  renames[id.name] = new_name
  id.name = new_name
end

# Walks the syntax AST depth-first and yields each node.
def walk_ast(node, &block)
  return if node.nil?

  yield node

  case node
  when Foxtail::Syntax::Parser::AST::Resource
    node.body.each {|child| walk_ast(child, &block) }
  when Foxtail::Syntax::Parser::AST::Message, Foxtail::Syntax::Parser::AST::Term
    walk_ast(node.value, &block) if node.value
    node.attributes.each {|attr| walk_ast(attr, &block) }
  when Foxtail::Syntax::Parser::AST::Attribute,
       Foxtail::Syntax::Parser::AST::Variant,
       Foxtail::Syntax::Parser::AST::NamedArgument

    walk_ast(node.value, &block)
  when Foxtail::Syntax::Parser::AST::Pattern
    node.elements.each {|elem| walk_ast(elem, &block) }
  when Foxtail::Syntax::Parser::AST::Placeable
    walk_ast(node.expression, &block)
  when Foxtail::Syntax::Parser::AST::SelectExpression
    walk_ast(node.selector, &block)
    node.variants.each {|variant| walk_ast(variant, &block) }
  when Foxtail::Syntax::Parser::AST::FunctionReference, Foxtail::Syntax::Parser::AST::TermReference
    walk_ast(node.arguments, &block) if node.arguments
  when Foxtail::Syntax::Parser::AST::CallArguments
    node.positional.each {|arg| walk_ast(arg, &block) }
    node.named.each {|arg| walk_ast(arg, &block) }
  end
end

walk_ast(resource) do |node|
  next unless node.is_a?(Foxtail::Syntax::Parser::AST::MessageReference)

  new_name = renames[node.id.name]
  node.id.name = new_name if new_name
end

serializer = Foxtail::Syntax::Serializer.new(with_junk: true)
puts serializer.serialize(resource)
