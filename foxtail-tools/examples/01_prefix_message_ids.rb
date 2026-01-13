# frozen_string_literal: true

# Example 01: Prefix Message IDs
#
# This example demonstrates:
# - Parsing FTL into the syntax AST
# - Using each_message to iterate over messages
# - Using the Visitor pattern to traverse the AST deeply
# - Renaming message IDs with a "msg-" prefix
# - Updating message references throughout the AST
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

# Step 1: Collect message IDs and rename them using each_message
renames = {}
resource.each_message do |message|
  next if message.id.name.start_with?(PREFIX)

  new_name = "#{PREFIX}#{message.id.name}"
  renames[message.id.name] = new_name
  message.id.name = new_name
end

# Visitor to update message references with new names
# Visitor pattern is needed here to traverse deeply into message values
class MessageReferenceUpdater
  include Foxtail::Syntax::Visitor

  def initialize(renames)
    @renames = renames
  end

  # Update message reference ID if it was renamed
  def visit_message_reference(node)
    new_name = @renames[node.id.name]
    node.id.name = new_name if new_name
    # Don't call super - MessageReference has no relevant children
  end
end

# Step 2: Update all message references
updater = MessageReferenceUpdater.new(renames)
resource.accept(updater)

# Output the transformed FTL
serializer = Foxtail::Syntax::Serializer.new(with_junk: true)
puts serializer.serialize(resource)
