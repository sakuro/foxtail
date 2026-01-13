# frozen_string_literal: true

# Example 01: Prefix Message IDs
#
# This example demonstrates:
# - Parsing FTL into the syntax AST
# - Using the Visitor pattern to traverse the AST
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

# Visitor to collect and rename message IDs
# Note: For this shallow traversal, a simple `each` loop would suffice.
# We use Visitor here to demonstrate the pattern.
class MessageIdPrefixer
  include Foxtail::Syntax::Visitor

  def initialize(prefix)
    @prefix = prefix
    @renames = {}
  end

  attr_reader :renames

  def visit_message(node)
    unless node.id.name.start_with?(@prefix)
      new_name = "#{@prefix}#{node.id.name}"
      @renames[node.id.name] = new_name
      node.id.name = new_name
    end
    # Don't call super - no need to traverse into message children
  end
end

# Visitor to update message references with new names
class MessageReferenceUpdater
  include Foxtail::Syntax::Visitor

  def initialize(renames)
    @renames = renames
  end

  def visit_message_reference(node)
    new_name = @renames[node.id.name]
    node.id.name = new_name if new_name
    # Don't call super - MessageReference has no relevant children
  end
end

# Step 1: Collect message IDs and rename them
prefixer = MessageIdPrefixer.new(PREFIX)
resource.accept(prefixer)

# Step 2: Update all message references
updater = MessageReferenceUpdater.new(prefixer.renames)
resource.accept(updater)

# Output the transformed FTL
serializer = Foxtail::Syntax::Serializer.new(with_junk: true)
puts serializer.serialize(resource)
