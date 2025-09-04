# frozen_string_literal: true

require "spec_helper"

RSpec.describe Foxtail::BaseNode do
  describe "basic functionality" do
    let(:node1) { Foxtail::Identifier.new("hello") }
    let(:node2) { Foxtail::Identifier.new("hello") }
    let(:node3) { Foxtail::Identifier.new("world") }

    it "sets type automatically from class name" do
      expect(node1.type).to eq("Identifier")
    end

    it "compares nodes for equality" do
      expect(node1 == node2).to be true
      expect(node1 == node3).to be false
    end

    it "converts to hash" do
      hash = node1.to_h
      expect(hash["type"]).to eq("Identifier")
      expect(hash["name"]).to eq("hello")
    end
  end
end

RSpec.describe Foxtail::SyntaxNode do
  let(:node) { Foxtail::TextElement.new("hello") }

  it "can add span information" do
    node.add_span(0, 5)
    expect(node.span).to be_a(Foxtail::Span)
    expect(node.span.start).to eq(0)
    expect(node.span.end).to eq(5)
  end
end

RSpec.describe Foxtail::Span do
  let(:span) { described_class.new(10, 20) }

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

RSpec.describe Foxtail::Resource do
  it "initializes with empty body by default" do
    resource = described_class.new
    expect(resource.type).to eq("Resource")
    expect(resource.body).to eq([])
  end

  it "accepts initial body" do
    message = Foxtail::Message.new(Foxtail::Identifier.new("test"))
    resource = described_class.new([message])
    expect(resource.body).to eq([message])
  end

  it "converts to hash with nested nodes" do
    message = Foxtail::Message.new(Foxtail::Identifier.new("test"))
    resource = described_class.new([message])
    hash = resource.to_h

    expect(hash["type"]).to eq("Resource")
    expect(hash["body"]).to be_a(Array)
    expect(hash["body"][0]["type"]).to eq("Message")
    expect(hash["body"][0]["id"]["type"]).to eq("Identifier")
    expect(hash["body"][0]["id"]["name"]).to eq("test")
  end
end

RSpec.describe Foxtail::Message do
  let(:id) { Foxtail::Identifier.new("hello") }
  let(:pattern) { Foxtail::Pattern.new([Foxtail::TextElement.new("Hello world")]) }

  it "initializes with required id" do
    message = described_class.new(id)
    expect(message.type).to eq("Message")
    expect(message.id).to eq(id)
    expect(message.value).to be_nil
    expect(message.attributes).to eq([])
    expect(message.comment).to be_nil
  end

  it "accepts optional parameters" do
    attribute = Foxtail::Attribute.new(Foxtail::Identifier.new("attr"), pattern)
    comment = Foxtail::Comment.new("A comment")
    
    message = described_class.new(id, pattern, [attribute], comment)
    expect(message.value).to eq(pattern)
    expect(message.attributes).to eq([attribute])
    expect(message.comment).to eq(comment)
  end
end

RSpec.describe Foxtail::Term do
  let(:id) { Foxtail::Identifier.new("brand-name") }
  let(:pattern) { Foxtail::Pattern.new([Foxtail::TextElement.new("Firefox")]) }

  it "initializes with required id and value" do
    term = described_class.new(id, pattern)
    expect(term.type).to eq("Term")
    expect(term.id).to eq(id)
    expect(term.value).to eq(pattern)
    expect(term.attributes).to eq([])
    expect(term.comment).to be_nil
  end
end

RSpec.describe Foxtail::Pattern do
  let(:elements) do
    [
      Foxtail::TextElement.new("Hello "),
      Foxtail::Placeable.new(Foxtail::VariableReference.new(Foxtail::Identifier.new("name")))
    ]
  end

  it "initializes with elements" do
    pattern = described_class.new(elements)
    expect(pattern.type).to eq("Pattern")
    expect(pattern.elements).to eq(elements)
  end
end

RSpec.describe Foxtail::TextElement do
  let(:element) { described_class.new("Hello world") }

  it "stores text value" do
    expect(element.type).to eq("TextElement")
    expect(element.value).to eq("Hello world")
  end
end

RSpec.describe Foxtail::Placeable do
  let(:expr) { Foxtail::VariableReference.new(Foxtail::Identifier.new("name")) }
  let(:placeable) { described_class.new(expr) }

  it "wraps an expression" do
    expect(placeable.type).to eq("Placeable")
    expect(placeable.expression).to eq(expr)
  end
end

RSpec.describe Foxtail::Identifier do
  let(:identifier) { described_class.new("message-id") }

  it "stores identifier name" do
    expect(identifier.type).to eq("Identifier")
    expect(identifier.name).to eq("message-id")
  end
end

RSpec.describe Foxtail::StringLiteral do
  it "handles simple strings" do
    literal = described_class.new("Hello")
    result = literal.parse
    expect(result[:value]).to eq("Hello")
  end

  it "handles escaped characters" do
    literal = described_class.new("Hello \\\"world\\\"")
    result = literal.parse
    expect(result[:value]).to eq('Hello "world"')
  end

  it "handles escaped backslashes" do
    literal = described_class.new("Path\\\\to\\\\file")
    result = literal.parse
    expect(result[:value]).to eq("Path\\to\\file")
  end

  it "handles unicode escapes" do
    literal = described_class.new("Smile \\u263A")
    result = literal.parse
    expect(result[:value]).to eq("Smile ☺")
  end

  it "handles invalid surrogate pairs" do
    literal = described_class.new("\\uD800") # High surrogate without pair
    result = literal.parse
    expect(result[:value]).to eq("\uFFFD") # Replacement character
  end
end

RSpec.describe Foxtail::NumberLiteral do
  it "parses integer literals" do
    literal = described_class.new("42")
    result = literal.parse
    expect(result[:value]).to eq(42)
  end

  it "parses float literals" do
    literal = described_class.new("3.14")
    result = literal.parse
    expect(result[:value]).to eq(3.14)
  end

  it "parses negative numbers" do
    literal = described_class.new("-123")
    result = literal.parse
    expect(result[:value]).to eq(-123)
  end
end

RSpec.describe Foxtail::VariableReference do
  let(:id) { Foxtail::Identifier.new("userName") }
  let(:var_ref) { described_class.new(id) }

  it "references a variable" do
    expect(var_ref.type).to eq("VariableReference")
    expect(var_ref.id).to eq(id)
  end
end

RSpec.describe Foxtail::MessageReference do
  let(:id) { Foxtail::Identifier.new("hello") }
  let(:attribute) { Foxtail::Identifier.new("title") }

  it "references a message without attribute" do
    msg_ref = described_class.new(id)
    expect(msg_ref.type).to eq("MessageReference")
    expect(msg_ref.id).to eq(id)
    expect(msg_ref.attribute).to be_nil
  end

  it "references a message attribute" do
    msg_ref = described_class.new(id, attribute)
    expect(msg_ref.id).to eq(id)
    expect(msg_ref.attribute).to eq(attribute)
  end
end

RSpec.describe Foxtail::SelectExpression do
  let(:selector) { Foxtail::VariableReference.new(Foxtail::Identifier.new("count")) }
  let(:variants) do
    [
      Foxtail::Variant.new(
        Foxtail::Identifier.new("one"),
        Foxtail::Pattern.new([Foxtail::TextElement.new("One item")])
      ),
      Foxtail::Variant.new(
        Foxtail::Identifier.new("other"),
        Foxtail::Pattern.new([Foxtail::TextElement.new("Many items")]),
        true # default
      )
    ]
  end

  it "creates a select expression" do
    select = described_class.new(selector, variants)
    expect(select.type).to eq("SelectExpression")
    expect(select.selector).to eq(selector)
    expect(select.variants).to eq(variants)
  end
end

RSpec.describe Foxtail::Variant do
  let(:key) { Foxtail::Identifier.new("one") }
  let(:value) { Foxtail::Pattern.new([Foxtail::TextElement.new("One item")]) }

  it "creates a variant without default" do
    variant = described_class.new(key, value)
    expect(variant.type).to eq("Variant")
    expect(variant.key).to eq(key)
    expect(variant.value).to eq(value)
    expect(variant.default).to be false
  end

  it "creates a default variant" do
    variant = described_class.new(key, value, true)
    expect(variant.default).to be true
  end
end

RSpec.describe Foxtail::Comment do
  let(:comment) { described_class.new("This is a comment") }

  it "stores comment content" do
    expect(comment.type).to eq("Comment")
    expect(comment.content).to eq("This is a comment")
  end
end

RSpec.describe Foxtail::Junk do
  let(:junk) { described_class.new("unparseable content") }

  it "stores junk content" do
    expect(junk.type).to eq("Junk")
    expect(junk.content).to eq("unparseable content")
    expect(junk.annotations).to eq([])
  end

  it "accepts annotations" do
    annotation = Foxtail::Annotation.new("E0001", [], "Parse error")
    junk = described_class.new("bad content", [annotation])
    expect(junk.annotations).to eq([annotation])
  end
end

RSpec.describe "AST node equality with spans" do
  it "ignores span in equality comparison by default" do
    node1 = Foxtail::TextElement.new("hello")
    node1.add_span(0, 5)
    
    node2 = Foxtail::TextElement.new("hello")
    node2.add_span(10, 15)
    
    expect(node1 == node2).to be true # Should ignore different spans
  end

  it "can include span in equality comparison" do
    node1 = Foxtail::TextElement.new("hello")
    node1.add_span(0, 5)
    
    node2 = Foxtail::TextElement.new("hello")
    node2.add_span(10, 15)
    
    expect(node1.==(node2, [])).to be false # Should consider spans when no fields ignored
  end
end