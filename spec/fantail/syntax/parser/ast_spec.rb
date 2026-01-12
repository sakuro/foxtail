# frozen_string_literal: true

RSpec.describe Fantail::Syntax::Parser::AST::BaseNode do
  describe "basic functionality" do
    let(:hello_node) { Fantail::Syntax::Parser::AST::Identifier.new("hello") }
    let(:other_hello_node) { Fantail::Syntax::Parser::AST::Identifier.new("hello") }
    let(:world_node) { Fantail::Syntax::Parser::AST::Identifier.new("world") }

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

RSpec.describe Fantail::Syntax::Parser::AST::SyntaxNode do
  let(:node) { Fantail::Syntax::Parser::AST::TextElement.new("hello") }

  it "can add span information" do
    node.add_span(0, 5)
    expect(node.span).to be_a(Fantail::Syntax::Parser::AST::Span)
    expect(node.span.start).to eq(0)
    expect(node.span.end).to eq(5)
  end
end

RSpec.describe Fantail::Syntax::Parser::AST::Span do
  let(:span) { Fantail::Syntax::Parser::AST::Span.new(10, 20) }

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

RSpec.describe Fantail::Syntax::Parser::AST::Resource do
  it "initializes with empty body by default" do
    resource = Fantail::Syntax::Parser::AST::Resource.new
    expect(resource.type).to eq("Resource")
    expect(resource.body).to eq([])
  end

  it "accepts initial body" do
    message = Fantail::Syntax::Parser::AST::Message.new(Fantail::Syntax::Parser::AST::Identifier.new("test"))
    resource = Fantail::Syntax::Parser::AST::Resource.new([message])
    expect(resource.body).to eq([message])
  end

  it "converts to hash with nested nodes" do
    message = Fantail::Syntax::Parser::AST::Message.new(Fantail::Syntax::Parser::AST::Identifier.new("test"))
    resource = Fantail::Syntax::Parser::AST::Resource.new([message])
    hash = resource.to_h

    expect(hash["type"]).to eq("Resource")
    expect(hash["body"]).to be_a(Array)
    expect(hash["body"][0]["type"]).to eq("Message")
    expect(hash["body"][0]["id"]["type"]).to eq("Identifier")
    expect(hash["body"][0]["id"]["name"]).to eq("test")
  end
end

RSpec.describe Fantail::Syntax::Parser::AST::Message do
  let(:id) { Fantail::Syntax::Parser::AST::Identifier.new("hello") }
  let(:pattern) { Fantail::Syntax::Parser::AST::Pattern.new([Fantail::Syntax::Parser::AST::TextElement.new("Hello world")]) }

  it "initializes with required id" do
    message = Fantail::Syntax::Parser::AST::Message.new(id)
    expect(message.type).to eq("Message")
    expect(message.id).to eq(id)
    expect(message.value).to be_nil
    expect(message.attributes).to eq([])
    expect(message.comment).to be_nil
  end

  it "accepts optional parameters" do
    attribute = Fantail::Syntax::Parser::AST::Attribute.new(Fantail::Syntax::Parser::AST::Identifier.new("attr"), pattern)
    comment = Fantail::Syntax::Parser::AST::Comment.new("A comment")

    message = Fantail::Syntax::Parser::AST::Message.new(id, pattern, [attribute], comment)
    expect(message.value).to eq(pattern)
    expect(message.attributes).to eq([attribute])
    expect(message.comment).to eq(comment)
  end
end

RSpec.describe Fantail::Syntax::Parser::AST::Term do
  let(:id) { Fantail::Syntax::Parser::AST::Identifier.new("brand-name") }
  let(:pattern) { Fantail::Syntax::Parser::AST::Pattern.new([Fantail::Syntax::Parser::AST::TextElement.new("Firefox")]) }

  it "initializes with required id and value" do
    term = Fantail::Syntax::Parser::AST::Term.new(id, pattern)
    expect(term.type).to eq("Term")
    expect(term.id).to eq(id)
    expect(term.value).to eq(pattern)
    expect(term.attributes).to eq([])
    expect(term.comment).to be_nil
  end
end

RSpec.describe Fantail::Syntax::Parser::AST::Pattern do
  let(:elements) do
    [
      Fantail::Syntax::Parser::AST::TextElement.new("Hello "),
      Fantail::Syntax::Parser::AST::Placeable.new(Fantail::Syntax::Parser::AST::VariableReference.new(Fantail::Syntax::Parser::AST::Identifier.new("name")))
    ]
  end

  it "initializes with elements" do
    pattern = Fantail::Syntax::Parser::AST::Pattern.new(elements)
    expect(pattern.type).to eq("Pattern")
    expect(pattern.elements).to eq(elements)
  end
end

RSpec.describe Fantail::Syntax::Parser::AST::TextElement do
  let(:element) { Fantail::Syntax::Parser::AST::TextElement.new("Hello world") }

  it "stores text value" do
    expect(element.type).to eq("TextElement")
    expect(element.value).to eq("Hello world")
  end
end

RSpec.describe Fantail::Syntax::Parser::AST::Placeable do
  let(:expr) { Fantail::Syntax::Parser::AST::VariableReference.new(Fantail::Syntax::Parser::AST::Identifier.new("name")) }
  let(:placeable) { Fantail::Syntax::Parser::AST::Placeable.new(expr) }

  it "wraps an expression" do
    expect(placeable.type).to eq("Placeable")
    expect(placeable.expression).to eq(expr)
  end
end

RSpec.describe Fantail::Syntax::Parser::AST::Identifier do
  let(:identifier) { Fantail::Syntax::Parser::AST::Identifier.new("message-id") }

  it "stores identifier name" do
    expect(identifier.type).to eq("Identifier")
    expect(identifier.name).to eq("message-id")
  end
end

RSpec.describe Fantail::Syntax::Parser::AST::StringLiteral do
  it "handles simple strings" do
    literal = Fantail::Syntax::Parser::AST::StringLiteral.new("Hello")
    result = literal.parse
    expect(result[:value]).to eq("Hello")
  end

  it "handles escaped characters" do
    literal = Fantail::Syntax::Parser::AST::StringLiteral.new("Hello \\\"world\\\"")
    result = literal.parse
    expect(result[:value]).to eq('Hello "world"')
  end

  it "handles escaped backslashes" do
    literal = Fantail::Syntax::Parser::AST::StringLiteral.new("Path\\\\to\\\\file")
    result = literal.parse
    expect(result[:value]).to eq("Path\\to\\file")
  end

  it "handles unicode escapes" do
    literal = Fantail::Syntax::Parser::AST::StringLiteral.new("Smile \\u263A")
    result = literal.parse
    expect(result[:value]).to eq("Smile ☺")
  end

  it "handles invalid surrogate pairs" do
    literal = Fantail::Syntax::Parser::AST::StringLiteral.new("\\uD800") # High surrogate without pair
    result = literal.parse
    expect(result[:value]).to eq("\uFFFD") # Replacement character
  end
end

RSpec.describe Fantail::Syntax::Parser::AST::NumberLiteral do
  it "parses integer literals" do
    literal = Fantail::Syntax::Parser::AST::NumberLiteral.new("42")
    result = literal.parse
    expect(result[:value]).to eq(42)
  end

  it "parses float literals" do
    literal = Fantail::Syntax::Parser::AST::NumberLiteral.new("3.14")
    result = literal.parse
    expect(result[:value]).to eq(3.14)
  end

  it "parses negative numbers" do
    literal = Fantail::Syntax::Parser::AST::NumberLiteral.new("-123")
    result = literal.parse
    expect(result[:value]).to eq(-123)
  end
end

RSpec.describe Fantail::Syntax::Parser::AST::VariableReference do
  let(:id) { Fantail::Syntax::Parser::AST::Identifier.new("userName") }
  let(:var_ref) { Fantail::Syntax::Parser::AST::VariableReference.new(id) }

  it "references a variable" do
    expect(var_ref.type).to eq("VariableReference")
    expect(var_ref.id).to eq(id)
  end
end

RSpec.describe Fantail::Syntax::Parser::AST::MessageReference do
  let(:id) { Fantail::Syntax::Parser::AST::Identifier.new("hello") }
  let(:attribute) { Fantail::Syntax::Parser::AST::Identifier.new("title") }

  it "references a message without attribute" do
    msg_ref = Fantail::Syntax::Parser::AST::MessageReference.new(id)
    expect(msg_ref.type).to eq("MessageReference")
    expect(msg_ref.id).to eq(id)
    expect(msg_ref.attribute).to be_nil
  end

  it "references a message attribute" do
    msg_ref = Fantail::Syntax::Parser::AST::MessageReference.new(id, attribute)
    expect(msg_ref.id).to eq(id)
    expect(msg_ref.attribute).to eq(attribute)
  end
end

RSpec.describe Fantail::Syntax::Parser::AST::SelectExpression do
  let(:selector) { Fantail::Syntax::Parser::AST::VariableReference.new(Fantail::Syntax::Parser::AST::Identifier.new("count")) }
  let(:variants) do
    [
      Fantail::Syntax::Parser::AST::Variant.new(
        Fantail::Syntax::Parser::AST::Identifier.new("one"),
        Fantail::Syntax::Parser::AST::Pattern.new([Fantail::Syntax::Parser::AST::TextElement.new("One item")])
      ),
      Fantail::Syntax::Parser::AST::Variant.new(
        Fantail::Syntax::Parser::AST::Identifier.new("other"),
        Fantail::Syntax::Parser::AST::Pattern.new([Fantail::Syntax::Parser::AST::TextElement.new("Many items")]),
        default: true
      )
    ]
  end

  it "creates a select expression" do
    select = Fantail::Syntax::Parser::AST::SelectExpression.new(selector, variants)
    expect(select.type).to eq("SelectExpression")
    expect(select.selector).to eq(selector)
    expect(select.variants).to eq(variants)
  end
end

RSpec.describe Fantail::Syntax::Parser::AST::Variant do
  let(:key) { Fantail::Syntax::Parser::AST::Identifier.new("one") }
  let(:value) { Fantail::Syntax::Parser::AST::Pattern.new([Fantail::Syntax::Parser::AST::TextElement.new("One item")]) }

  it "creates a variant without default" do
    variant = Fantail::Syntax::Parser::AST::Variant.new(key, value)
    expect(variant.type).to eq("Variant")
    expect(variant.key).to eq(key)
    expect(variant.value).to eq(value)
    expect(variant.default).to be false
  end

  it "creates a default variant" do
    variant = Fantail::Syntax::Parser::AST::Variant.new(key, value, default: true)
    expect(variant.default).to be true
  end
end

RSpec.describe Fantail::Syntax::Parser::AST::Comment do
  let(:comment) { Fantail::Syntax::Parser::AST::Comment.new("This is a comment") }

  it "stores comment content" do
    expect(comment.type).to eq("Comment")
    expect(comment.content).to eq("This is a comment")
  end
end

RSpec.describe Fantail::Syntax::Parser::AST::Junk do
  let(:junk) { Fantail::Syntax::Parser::AST::Junk.new("unparseable content") }

  it "stores junk content" do
    expect(junk.type).to eq("Junk")
    expect(junk.content).to eq("unparseable content")
    expect(junk.annotations).to eq([])
  end

  it "accepts annotations" do
    annotation = Fantail::Syntax::Parser::AST::Annotation.new("E0001", [], "Parse error")
    junk = Fantail::Syntax::Parser::AST::Junk.new("bad content", [annotation])
    expect(junk.annotations).to eq([annotation])
  end
end

RSpec.describe "AST node equality with spans" do
  it "ignores span in equality comparison" do
    node1 = Fantail::Syntax::Parser::AST::TextElement.new("hello")
    node1.add_span(0, 5)

    node2 = Fantail::Syntax::Parser::AST::TextElement.new("hello")
    node2.add_span(10, 15)

    expect(node1 == node2).to be true # Should ignore different spans
  end
end
