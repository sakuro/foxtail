# frozen_string_literal: true

require "spec_helper"

RSpec.describe Foxtail::Parser::AST::BaseNode do
  describe "basic functionality" do
    let(:hello_node) { Foxtail::Parser::AST::Identifier.new("hello") }
    let(:other_hello_node) { Foxtail::Parser::AST::Identifier.new("hello") }
    let(:world_node) { Foxtail::Parser::AST::Identifier.new("world") }

    it "sets type automatically from class name" do
      expect(hello_node.type).to eq("Identifier")
    end

    it "compares nodes for equality" do
      expect(hello_node == other_hello_node).to be true
      expect(hello_node == world_node).to be false
    end

    it "converts to hash" do
      hash = hello_node.to_h
      expect(hash["type"]).to eq("Identifier")
      expect(hash["name"]).to eq("hello")
    end
  end
end

RSpec.describe Foxtail::Parser::AST::SyntaxNode do
  let(:node) { Foxtail::Parser::AST::TextElement.new("hello") }

  it "can add span information" do
    node.add_span(0, 5)
    expect(node.span).to be_a(Foxtail::Parser::AST::Span)
    expect(node.span.start).to eq(0)
    expect(node.span.end).to eq(5)
  end
end

RSpec.describe Foxtail::Parser::AST::Span do
  let(:span) { Foxtail::Parser::AST::Span.new(10, 20) }

  it "stores start and end positions" do
    expect(span.type).to eq("Span")
    expect(span.start).to eq(10)
    expect(span.end).to eq(20)
  end

  it "converts to hash correctly" do
    hash = span.to_h
    expect(hash).to eq({
      "type" => "Span",
      "start" => 10,
      "end" => 20
    })
  end
end

RSpec.describe Foxtail::Parser::AST::Resource do
  it "initializes with empty body by default" do
    resource = Foxtail::Parser::AST::Resource.new
    expect(resource.type).to eq("Resource")
    expect(resource.body).to eq([])
  end

  it "accepts initial body" do
    message = Foxtail::Parser::AST::Message.new(Foxtail::Parser::AST::Identifier.new("test"))
    resource = Foxtail::Parser::AST::Resource.new([message])
    expect(resource.body).to eq([message])
  end

  it "converts to hash with nested nodes" do
    message = Foxtail::Parser::AST::Message.new(Foxtail::Parser::AST::Identifier.new("test"))
    resource = Foxtail::Parser::AST::Resource.new([message])
    hash = resource.to_h

    expect(hash["type"]).to eq("Resource")
    expect(hash["body"]).to be_a(Array)
    expect(hash["body"][0]["type"]).to eq("Message")
    expect(hash["body"][0]["id"]["type"]).to eq("Identifier")
    expect(hash["body"][0]["id"]["name"]).to eq("test")
  end
end

RSpec.describe Foxtail::Parser::AST::Message do
  let(:id) { Foxtail::Parser::AST::Identifier.new("hello") }
  let(:pattern) { Foxtail::Parser::AST::Pattern.new([Foxtail::Parser::AST::TextElement.new("Hello world")]) }

  it "initializes with required id" do
    message = Foxtail::Parser::AST::Message.new(id)
    expect(message.type).to eq("Message")
    expect(message.id).to eq(id)
    expect(message.value).to be_nil
    expect(message.attributes).to eq([])
    expect(message.comment).to be_nil
  end

  it "accepts optional parameters" do
    attribute = Foxtail::Parser::AST::Attribute.new(Foxtail::Parser::AST::Identifier.new("attr"), pattern)
    comment = Foxtail::Parser::AST::Comment.new("A comment")

    message = Foxtail::Parser::AST::Message.new(id, pattern, [attribute], comment)
    expect(message.value).to eq(pattern)
    expect(message.attributes).to eq([attribute])
    expect(message.comment).to eq(comment)
  end
end

RSpec.describe Foxtail::Parser::AST::Term do
  let(:id) { Foxtail::Parser::AST::Identifier.new("brand-name") }
  let(:pattern) { Foxtail::Parser::AST::Pattern.new([Foxtail::Parser::AST::TextElement.new("Firefox")]) }

  it "initializes with required id and value" do
    term = Foxtail::Parser::AST::Term.new(id, pattern)
    expect(term.type).to eq("Term")
    expect(term.id).to eq(id)
    expect(term.value).to eq(pattern)
    expect(term.attributes).to eq([])
    expect(term.comment).to be_nil
  end
end

RSpec.describe Foxtail::Parser::AST::Pattern do
  let(:elements) do
    [
      Foxtail::Parser::AST::TextElement.new("Hello "),
      Foxtail::Parser::AST::Placeable.new(Foxtail::Parser::AST::VariableReference.new(Foxtail::Parser::AST::Identifier.new("name")))
    ]
  end

  it "initializes with elements" do
    pattern = Foxtail::Parser::AST::Pattern.new(elements)
    expect(pattern.type).to eq("Pattern")
    expect(pattern.elements).to eq(elements)
  end
end

RSpec.describe Foxtail::Parser::AST::TextElement do
  let(:element) { Foxtail::Parser::AST::TextElement.new("Hello world") }

  it "stores text value" do
    expect(element.type).to eq("TextElement")
    expect(element.value).to eq("Hello world")
  end
end

RSpec.describe Foxtail::Parser::AST::Placeable do
  let(:expr) { Foxtail::Parser::AST::VariableReference.new(Foxtail::Parser::AST::Identifier.new("name")) }
  let(:placeable) { Foxtail::Parser::AST::Placeable.new(expr) }

  it "wraps an expression" do
    expect(placeable.type).to eq("Placeable")
    expect(placeable.expression).to eq(expr)
  end
end

RSpec.describe Foxtail::Parser::AST::Identifier do
  let(:identifier) { Foxtail::Parser::AST::Identifier.new("message-id") }

  it "stores identifier name" do
    expect(identifier.type).to eq("Identifier")
    expect(identifier.name).to eq("message-id")
  end
end

RSpec.describe Foxtail::Parser::AST::StringLiteral do
  it "handles simple strings" do
    literal = Foxtail::Parser::AST::StringLiteral.new("Hello")
    result = literal.parse
    expect(result[:value]).to eq("Hello")
  end

  it "handles escaped characters" do
    literal = Foxtail::Parser::AST::StringLiteral.new("Hello \\\"world\\\"")
    result = literal.parse
    expect(result[:value]).to eq('Hello "world"')
  end

  it "handles escaped backslashes" do
    literal = Foxtail::Parser::AST::StringLiteral.new("Path\\\\to\\\\file")
    result = literal.parse
    expect(result[:value]).to eq("Path\\to\\file")
  end

  it "handles unicode escapes" do
    literal = Foxtail::Parser::AST::StringLiteral.new("Smile \\u263A")
    result = literal.parse
    expect(result[:value]).to eq("Smile ☺")
  end

  it "handles invalid surrogate pairs" do
    literal = Foxtail::Parser::AST::StringLiteral.new("\\uD800") # High surrogate without pair
    result = literal.parse
    expect(result[:value]).to eq("\uFFFD") # Replacement character
  end
end

RSpec.describe Foxtail::Parser::AST::NumberLiteral do
  it "parses integer literals" do
    literal = Foxtail::Parser::AST::NumberLiteral.new("42")
    result = literal.parse
    expect(result[:value]).to eq(42)
  end

  it "parses float literals" do
    literal = Foxtail::Parser::AST::NumberLiteral.new("3.14")
    result = literal.parse
    expect(result[:value]).to eq(3.14)
  end

  it "parses negative numbers" do
    literal = Foxtail::Parser::AST::NumberLiteral.new("-123")
    result = literal.parse
    expect(result[:value]).to eq(-123)
  end
end

RSpec.describe Foxtail::Parser::AST::VariableReference do
  let(:id) { Foxtail::Parser::AST::Identifier.new("userName") }
  let(:var_ref) { Foxtail::Parser::AST::VariableReference.new(id) }

  it "references a variable" do
    expect(var_ref.type).to eq("VariableReference")
    expect(var_ref.id).to eq(id)
  end
end

RSpec.describe Foxtail::Parser::AST::MessageReference do
  let(:id) { Foxtail::Parser::AST::Identifier.new("hello") }
  let(:attribute) { Foxtail::Parser::AST::Identifier.new("title") }

  it "references a message without attribute" do
    msg_ref = Foxtail::Parser::AST::MessageReference.new(id)
    expect(msg_ref.type).to eq("MessageReference")
    expect(msg_ref.id).to eq(id)
    expect(msg_ref.attribute).to be_nil
  end

  it "references a message attribute" do
    msg_ref = Foxtail::Parser::AST::MessageReference.new(id, attribute)
    expect(msg_ref.id).to eq(id)
    expect(msg_ref.attribute).to eq(attribute)
  end
end

RSpec.describe Foxtail::Parser::AST::SelectExpression do
  let(:selector) { Foxtail::Parser::AST::VariableReference.new(Foxtail::Parser::AST::Identifier.new("count")) }
  let(:variants) do
    [
      Foxtail::Parser::AST::Variant.new(
        Foxtail::Parser::AST::Identifier.new("one"),
        Foxtail::Parser::AST::Pattern.new([Foxtail::Parser::AST::TextElement.new("One item")])
      ),
      Foxtail::Parser::AST::Variant.new(
        Foxtail::Parser::AST::Identifier.new("other"),
        Foxtail::Parser::AST::Pattern.new([Foxtail::Parser::AST::TextElement.new("Many items")]),
        default: true
      )
    ]
  end

  it "creates a select expression" do
    select = Foxtail::Parser::AST::SelectExpression.new(selector, variants)
    expect(select.type).to eq("SelectExpression")
    expect(select.selector).to eq(selector)
    expect(select.variants).to eq(variants)
  end
end

RSpec.describe Foxtail::Parser::AST::Variant do
  let(:key) { Foxtail::Parser::AST::Identifier.new("one") }
  let(:value) { Foxtail::Parser::AST::Pattern.new([Foxtail::Parser::AST::TextElement.new("One item")]) }

  it "creates a variant without default" do
    variant = Foxtail::Parser::AST::Variant.new(key, value)
    expect(variant.type).to eq("Variant")
    expect(variant.key).to eq(key)
    expect(variant.value).to eq(value)
    expect(variant.default).to be false
  end

  it "creates a default variant" do
    variant = Foxtail::Parser::AST::Variant.new(key, value, default: true)
    expect(variant.default).to be true
  end
end

RSpec.describe Foxtail::Parser::AST::Comment do
  let(:comment) { Foxtail::Parser::AST::Comment.new("This is a comment") }

  it "stores comment content" do
    expect(comment.type).to eq("Comment")
    expect(comment.content).to eq("This is a comment")
  end
end

RSpec.describe Foxtail::Parser::AST::Junk do
  let(:junk) { Foxtail::Parser::AST::Junk.new("unparseable content") }

  it "stores junk content" do
    expect(junk.type).to eq("Junk")
    expect(junk.content).to eq("unparseable content")
    expect(junk.annotations).to eq([])
  end

  it "accepts annotations" do
    annotation = Foxtail::Parser::AST::Annotation.new("E0001", [], "Parse error")
    junk = Foxtail::Parser::AST::Junk.new("bad content", [annotation])
    expect(junk.annotations).to eq([annotation])
  end
end

RSpec.describe "AST node equality with spans" do
  it "ignores span in equality comparison" do
    node1 = Foxtail::Parser::AST::TextElement.new("hello")
    node1.add_span(0, 5)

    node2 = Foxtail::Parser::AST::TextElement.new("hello")
    node2.add_span(10, 15)

    expect(node1 == node2).to be true # Should ignore different spans
  end
end
