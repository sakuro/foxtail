# frozen_string_literal: true

# Helper methods for FTL fixture-based tests
# This module provides common helper methods for finding specific entries in the parsed result
# and for converting AST nodes to JSON-compatible hash structures.
module FtlHelpers
  # Find a message by ID
  def find_message(id)
    result.body.find {|entry| entry.is_a?(Foxtail::AST::Message) && entry.id.name == id }
  end

  # Find a term by ID
  def find_term(id)
    result.body.find {|entry| entry.is_a?(Foxtail::AST::Term) && entry.id.name == id }
  end

  # Find a comment by content
  def find_comment(content)
    result.body.find {|entry| entry.is_a?(Foxtail::AST::Comment) && entry.content == content }
  end

  # Find a group comment by content
  def find_group_comment(content)
    result.body.find {|entry| entry.is_a?(Foxtail::AST::GroupComment) && entry.content == content }
  end

  # Find a resource comment by content
  def find_resource_comment(content)
    result.body.find {|entry| entry.is_a?(Foxtail::AST::ResourceComment) && entry.content == content }
  end

  # Convert Resource object to a JSON-compatible hash structure
  def resource_to_hash(resource)
    {
      "type" => resource.type,
      "body" => resource.body.map {|node| node_to_hash(node) }
    }
  end

  # Convert any AST node to a JSON-compatible hash structure
  def node_to_hash(node)
    hash = {"type" => node.type}

    case node
    when Foxtail::AST::Message
      hash["id"] = node_to_hash(node.id)
      hash["value"] = node_to_hash(node.value) if node.value
      hash["attributes"] = node.attributes.map {|attr| node_to_hash(attr) }
      hash["comment"] = node_to_hash(node.comment) if node.comment
    when Foxtail::AST::Term
      hash["id"] = node_to_hash(node.id)
      hash["value"] = node_to_hash(node.value) if node.value
      hash["attributes"] = node.attributes.map {|attr| node_to_hash(attr) }
      hash["comment"] = node_to_hash(node.comment) if node.comment
    when Foxtail::AST::Identifier
      hash["name"] = node.name
    when Foxtail::AST::Pattern
      hash["elements"] = node.elements.map {|elem| node_to_hash(elem) }
    when Foxtail::AST::TextElement
      hash["value"] = node.value
    when Foxtail::AST::Comment, Foxtail::AST::GroupComment, Foxtail::AST::ResourceComment
      hash["content"] = node.content
    when Foxtail::AST::Junk
      hash["content"] = node.content
      hash["annotations"] = node.annotations.map {|anno| node_to_hash(anno) }
    when Foxtail::AST::Annotation
      hash["code"] = node.code
      hash["arguments"] = node.arguments
      hash["message"] = node.message
    end

    hash
  end
end
