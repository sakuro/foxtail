# frozen_string_literal: true

require "json"
require "spec_helper"

RSpec.describe Foxtail::Parser do
  describe "#parse" do
    context "with simple message" do
      let(:ftl_file) { "spec/fixtures/structure/simple_message.ftl" }
      let(:json_file) { "spec/fixtures/structure/simple_message.json" }
      let(:source) { File.read(ftl_file) }
      let(:expected_json) { JSON.parse(File.read(json_file)) }

      it "parses correctly" do
        parser = Foxtail::Parser.new
        result = parser.parse(source)

        # 結果がResourceオブジェクトであることを確認
        expect(result).to be_a(Foxtail::AST::Resource)

        # bodyに1つのMessageが含まれていることを確認
        expect(result.body.size).to eq(1)
        expect(result.body[0]).to be_a(Foxtail::AST::Message)

        # Messageの内容を確認
        message = result.body[0]
        expect(message.id.name).to eq("foo")
        expect(message.value).to be_a(Foxtail::AST::Pattern)
        expect(message.value.elements.size).to eq(1)
        expect(message.value.elements[0]).to be_a(Foxtail::AST::TextElement)
        expect(message.value.elements[0].value).to eq("Foo")
        expect(message.attributes).to be_empty
        expect(message.comment).to be_nil
      end
    end

    context "with attribute" do
      let(:ftl_file) { "spec/fixtures/structure/attribute_starts_from_nl.ftl" }
      let(:json_file) { "spec/fixtures/structure/attribute_starts_from_nl.json" }
      let(:source) { File.read(ftl_file) }
      let(:expected_json) { JSON.parse(File.read(json_file)) }

      it "parses correctly" do
        parser = Foxtail::Parser.new
        result = parser.parse(source)

        # 結果がResourceオブジェクトであることを確認
        expect(result).to be_a(Foxtail::AST::Resource)

        # bodyに1つのMessageが含まれていることを確認
        expect(result.body.size).to eq(1)
        expect(result.body[0]).to be_a(Foxtail::AST::Message)

        # Messageの内容を確認
        message = result.body[0]
        expect(message.id.name).to eq("foo")
        expect(message.value).to be_a(Foxtail::AST::Pattern)
        expect(message.value.elements.size).to eq(1)
        expect(message.value.elements[0]).to be_a(Foxtail::AST::TextElement)
        expect(message.value.elements[0].value).to eq("Value")

        # 属性を確認
        expect(message.attributes.size).to eq(1)
        expect(message.attributes[0]).to be_a(Foxtail::AST::Attribute)
        expect(message.attributes[0].id.name).to eq("attr")
        expect(message.attributes[0].value).to be_a(Foxtail::AST::Pattern)
        expect(message.attributes[0].value.elements.size).to eq(1)
        expect(message.attributes[0].value.elements[0]).to be_a(Foxtail::AST::TextElement)
        expect(message.attributes[0].value.elements[0].value).to eq("Value 2")
      end
    end

    context "with select expression" do
      let(:ftl_file) { "spec/fixtures/structure/select_expression.ftl" }
      let(:json_file) { "spec/fixtures/structure/select_expression.json" }
      let(:source) { File.read(ftl_file) }
      let(:expected_json) { JSON.parse(File.read(json_file)) }

      it "parses correctly" do
        parser = Foxtail::Parser.new
        result = parser.parse(source)

        # 結果がResourceオブジェクトであることを確認
        expect(result).to be_a(Foxtail::AST::Resource)

        # bodyに1つのMessageが含まれていることを確認
        expect(result.body.size).to eq(1)
        expect(result.body[0]).to be_a(Foxtail::AST::Message)

        # Messageの内容を確認
        message = result.body[0]
        expect(message.id.name).to eq("emails")
        expect(message.value).to be_a(Foxtail::AST::Pattern)
        expect(message.value.elements.size).to eq(1)
        expect(message.value.elements[0]).to be_a(Foxtail::AST::Placeable)

        # Placeableの内容を確認
        placeable = message.value.elements[0]
        expect(placeable.expression).to be_a(Foxtail::AST::SelectExpression)

        # SelectExpressionの内容を確認
        select_expr = placeable.expression
        expect(select_expr.selector).to be_a(Foxtail::AST::VariableReference)
        expect(select_expr.selector.id.name).to eq("count")

        # Variantsの内容を確認
        expect(select_expr.variants.size).to eq(2)
        expect(select_expr.variants[0]).to be_a(Foxtail::AST::Variant)
        expect(select_expr.variants[0].key.name).to eq("one")
        expect(select_expr.variants[0].value).to be_a(Foxtail::AST::Pattern)
        expect(select_expr.variants[0].value.elements[0].value).to eq("You have one new email.")
        expect(select_expr.variants[0].default).to be_falsey

        expect(select_expr.variants[1]).to be_a(Foxtail::AST::Variant)
        expect(select_expr.variants[1].key.name).to eq("other")
        expect(select_expr.variants[1].value).to be_a(Foxtail::AST::Pattern)
        expect(select_expr.variants[1].default).to be_truthy

        # "other" variantのPatternの内容を確認
        other_pattern = select_expr.variants[1].value
        expect(other_pattern.elements.size).to eq(3)
        expect(other_pattern.elements[0]).to be_a(Foxtail::AST::TextElement)
        expect(other_pattern.elements[0].value).to eq("You have ")
        expect(other_pattern.elements[1]).to be_a(Foxtail::AST::Placeable)
        expect(other_pattern.elements[1].expression).to be_a(Foxtail::AST::VariableReference)
        expect(other_pattern.elements[1].expression.id.name).to eq("count")
        expect(other_pattern.elements[2]).to be_a(Foxtail::AST::TextElement)
        expect(other_pattern.elements[2].value).to eq(" new emails.")
      end
    end

    context "with variable reference" do
      let(:ftl_file) { "spec/fixtures/reference/variable_reference.ftl" }
      let(:json_file) { "spec/fixtures/reference/variable_reference.json" }
      let(:source) { File.read(ftl_file) }
      let(:expected_json) { JSON.parse(File.read(json_file)) }

      it "parses correctly" do
        parser = Foxtail::Parser.new
        result = parser.parse(source)

        # 結果がResourceオブジェクトであることを確認
        expect(result).to be_a(Foxtail::AST::Resource)

        # bodyに1つのMessageが含まれていることを確認
        expect(result.body.size).to eq(1)
        expect(result.body[0]).to be_a(Foxtail::AST::Message)

        # Messageの内容を確認
        message = result.body[0]
        expect(message.id.name).to eq("welcome")
        expect(message.value).to be_a(Foxtail::AST::Pattern)

        # Patternの内容を確認
        pattern = message.value
        expect(pattern.elements.size).to eq(3)
        expect(pattern.elements[0]).to be_a(Foxtail::AST::TextElement)
        expect(pattern.elements[0].value).to eq("Welcome, ")
        expect(pattern.elements[1]).to be_a(Foxtail::AST::Placeable)
        expect(pattern.elements[1].expression).to be_a(Foxtail::AST::VariableReference)
        expect(pattern.elements[1].expression.id.name).to eq("user")
        expect(pattern.elements[2]).to be_a(Foxtail::AST::TextElement)
        expect(pattern.elements[2].value).to eq("!")
      end
    end

    context "with message without value" do
      let(:ftl_file) { "spec/fixtures/structure/message_without_value.ftl" }
      let(:json_file) { "spec/fixtures/structure/message_without_value.json" }
      let(:source) { File.read(ftl_file) }
      let(:expected_json) { JSON.parse(File.read(json_file)) }

      it "parses as junk with error annotation" do
        parser = Foxtail::Parser.new
        result = parser.parse(source)

        # 結果がResourceオブジェクトであることを確認
        expect(result).to be_a(Foxtail::AST::Resource)

        # bodyに1つのJunkが含まれていることを確認
        expect(result.body.size).to eq(1)
        expect(result.body[0]).to be_a(Foxtail::AST::Junk)

        # Junkの内容を確認
        junk = result.body[0]
        expect(junk.content).to eq("foo =\n")

        # アノテーションを確認
        expect(junk.annotations.size).to eq(1)
        expect(junk.annotations[0]).to be_a(Foxtail::AST::Annotation)
        expect(junk.annotations[0].code).to eq("E0005")
        expect(junk.annotations[0].arguments).to eq(["foo"])
        expect(junk.annotations[0].message).to include("Expected message")
        expect(junk.annotations[0].message).to include("foo")
        expect(junk.annotations[0].message).to include("to have a value or attributes")
      end
    end

    context "with term" do
      let(:ftl_file) { "spec/fixtures/structure/term.ftl" }
      let(:json_file) { "spec/fixtures/structure/term.json" }
      let(:source) { File.read(ftl_file) }
      let(:expected_json) { JSON.parse(File.read(json_file)) }

      it "parses term definition and references correctly" do
        parser = Foxtail::Parser.new
        result = parser.parse(source)

        # 結果がResourceオブジェクトであることを確認
        expect(result).to be_a(Foxtail::AST::Resource)

        # bodyに複数のエントリが含まれていることを確認
        expect(result.body.size).to be > 1

        # 最初のエントリがTermであることを確認
        expect(result.body[0]).to be_a(Foxtail::AST::Term)
        term = result.body[0]
        expect(term.id.name).to eq("term")

        # Termの値がPatternであることを確認
        expect(term.value).to be_a(Foxtail::AST::Pattern)
        expect(term.value.elements.size).to eq(1)
        expect(term.value.elements[0]).to be_a(Foxtail::AST::Placeable)

        # Placeableの内容を確認
        placeable = term.value.elements[0]
        expect(placeable.expression).to be_a(Foxtail::AST::SelectExpression)

        # SelectExpressionの内容を確認
        select_expr = placeable.expression
        expect(select_expr.selector).to be_a(Foxtail::AST::VariableReference)
        expect(select_expr.selector.id.name).to eq("case")

        # Variantsの内容を確認
        expect(select_expr.variants.size).to eq(2)
        expect(select_expr.variants[0]).to be_a(Foxtail::AST::Variant)
        expect(select_expr.variants[0].key.name).to eq("uppercase")
        expect(select_expr.variants[0].default).to be_truthy

        # 属性を確認
        expect(term.attributes.size).to eq(1)
        expect(term.attributes[0]).to be_a(Foxtail::AST::Attribute)
        expect(term.attributes[0].id.name).to eq("attr")

        # 2番目のエントリがMessageであることを確認
        expect(result.body[1]).to be_a(Foxtail::AST::Message)
        message = result.body[1]
        expect(message.id.name).to eq("key01")

        # Messageの値がPatternであることを確認
        expect(message.value).to be_a(Foxtail::AST::Pattern)
        expect(message.value.elements.size).to eq(1)
        expect(message.value.elements[0]).to be_a(Foxtail::AST::Placeable)

        # Placeableの内容を確認
        placeable = message.value.elements[0]
        expect(placeable.expression).to be_a(Foxtail::AST::TermReference)
        expect(placeable.expression.id.name).to eq("term")
      end
    end

    context "with placeable in placeable" do
      let(:ftl_file) { "spec/fixtures/structure/placeable_in_placeable.ftl" }
      let(:json_file) { "spec/fixtures/structure/placeable_in_placeable.json" }
      let(:source) { File.read(ftl_file) }
      let(:expected_json) { JSON.parse(File.read(json_file)) }

      it "parses nested placeables correctly" do
        parser = Foxtail::Parser.new
        result = parser.parse(source)

        # 結果がResourceオブジェクトであることを確認
        expect(result).to be_a(Foxtail::AST::Resource)

        # bodyに複数のエントリが含まれていることを確認
        expect(result.body.size).to be > 1

        # 最初のエントリがMessageであることを確認
        expect(result.body[0]).to be_a(Foxtail::AST::Message)
        message = result.body[0]
        expect(message.id.name).to eq("key1")

        # Messageの値がPatternであることを確認
        expect(message.value).to be_a(Foxtail::AST::Pattern)
        expect(message.value.elements.size).to eq(1)
        expect(message.value.elements[0]).to be_a(Foxtail::AST::Placeable)

        # 外側のPlaceableの内容を確認
        outer_placeable = message.value.elements[0]
        expect(outer_placeable.expression).to be_a(Foxtail::AST::Placeable)

        # 内側のPlaceableの内容を確認
        inner_placeable = outer_placeable.expression
        expect(inner_placeable.expression).to be_a(Foxtail::AST::MessageReference)
        expect(inner_placeable.expression.id.name).to eq("foo")
      end
    end

    context "with escape sequences" do
      let(:ftl_file) { "spec/fixtures/structure/escape_sequences.ftl" }
      let(:json_file) { "spec/fixtures/structure/escape_sequences.json" }
      let(:source) { File.read(ftl_file) }
      let(:expected_json) { JSON.parse(File.read(json_file)) }

      it "parses escape sequences correctly" do
        pending("Escape sequence handling needs to be fixed")
        parser = Foxtail::Parser.new
        result = parser.parse(source)

        # 結果がResourceオブジェクトであることを確認
        expect(result).to be_a(Foxtail::AST::Resource)

        # bodyに複数のエントリが含まれていることを確認
        expect(result.body.size).to be > 1

        # GroupCommentが含まれていることを確認
        expect(result.body[0]).to be_a(Foxtail::AST::GroupComment)
        expect(result.body[0].content).to eq("Literal text")

        # バックスラッシュを含むメッセージを確認
        backslash_message = result.body.find {|entry|
          entry.is_a?(Foxtail::AST::Message) && entry.id.name == "text-backslash-one"
        }
        expect(backslash_message).not_to be_nil
        expect(backslash_message.value.elements[0].value).to include("\\")

        # 文字列リテラル内のクォートを確認
        quote_message = result.body.find {|entry|
          entry.is_a?(Foxtail::AST::Message) && entry.id.name == "quote-in-string"
        }
        expect(quote_message).not_to be_nil
        expect(quote_message.value.elements[0]).to be_a(Foxtail::AST::Placeable)
        expect(quote_message.value.elements[0].expression).to be_a(Foxtail::AST::StringLiteral)
        expect(quote_message.value.elements[0].expression.value).to include("\"")
      end
    end

    context "with resource comment" do
      let(:ftl_file) { "spec/fixtures/structure/resource_comment.ftl" }
      let(:json_file) { "spec/fixtures/structure/resource_comment.json" }
      let(:source) { File.read(ftl_file) }
      let(:expected_json) { JSON.parse(File.read(json_file)) }

      it "parses resource comment correctly" do
        parser = Foxtail::Parser.new
        result = parser.parse(source)

        # 結果がResourceオブジェクトであることを確認
        expect(result).to be_a(Foxtail::AST::Resource)

        # bodyに1つのResourceCommentが含まれていることを確認
        expect(result.body.size).to eq(1)
        expect(result.body[0]).to be_a(Foxtail::AST::ResourceComment)

        # ResourceCommentの内容を確認
        comment = result.body[0]
        expect(comment.content).to include("This is a resource wide comment")
        expect(comment.content).to include("It's multiline")
      end
    end

    context "with multiline pattern" do
      let(:ftl_file) { "spec/fixtures/structure/multiline_pattern.ftl" }
      let(:json_file) { "spec/fixtures/structure/multiline_pattern.json" }
      let(:source) { File.read(ftl_file) }
      let(:expected_json) { JSON.parse(File.read(json_file)) }

      it "parses multiline patterns correctly" do
        parser = Foxtail::Parser.new
        result = parser.parse(source)

        # 結果がResourceオブジェクトであることを確認
        expect(result).to be_a(Foxtail::AST::Resource)

        # bodyに複数のエントリが含まれていることを確認
        expect(result.body.size).to be > 1

        # key01のメッセージを確認
        message = result.body.find {|entry| entry.is_a?(Foxtail::AST::Message) && entry.id.name == "key01" }
        expect(message).not_to be_nil
        expect(message.value).to be_a(Foxtail::AST::Pattern)
        expect(message.value.elements.size).to eq(1)
        expect(message.value.elements[0]).to be_a(Foxtail::AST::TextElement)
        expect(message.value.elements[0].value).to eq("Value\nContinued here.")

        # key02のメッセージを確認
        message = result.body.find {|entry| entry.is_a?(Foxtail::AST::Message) && entry.id.name == "key02" }
        expect(message).not_to be_nil
        expect(message.value).to be_a(Foxtail::AST::Pattern)
        expect(message.value.elements.size).to eq(1)
        expect(message.value.elements[0]).to be_a(Foxtail::AST::TextElement)
        expect(message.value.elements[0].value).to eq("Value\nContinued here.")
      end
    end

    context "with variant keys" do
      let(:ftl_file) { "spec/fixtures/structure/variant_keys.ftl" }
      let(:json_file) { "spec/fixtures/structure/variant_keys.json" }
      let(:source) { File.read(ftl_file) }
      let(:expected_json) { JSON.parse(File.read(json_file)) }

      it "parses variant keys correctly" do
        parser = Foxtail::Parser.new
        result = parser.parse(source)

        # 結果がResourceオブジェクトであることを確認
        expect(result).to be_a(Foxtail::AST::Resource)

        # bodyに複数のエントリが含まれていることを確認
        expect(result.body.size).to be > 1

        # key01のメッセージを確認
        message = result.body.find {|entry| entry.is_a?(Foxtail::AST::Message) && entry.id.name == "key01" }
        expect(message).not_to be_nil
        expect(message.value).to be_a(Foxtail::AST::Pattern)
        expect(message.value.elements.size).to eq(1)
        expect(message.value.elements[0]).to be_a(Foxtail::AST::Placeable)
        expect(message.value.elements[0].expression).to be_a(Foxtail::AST::SelectExpression)

        # SelectExpressionの内容を確認
        select_expr = message.value.elements[0].expression
        expect(select_expr.selector).to be_a(Foxtail::AST::VariableReference)
        expect(select_expr.selector.id.name).to eq("sel")
        expect(select_expr.variants.size).to eq(1)
        expect(select_expr.variants[0].key.name).to eq("key")
        expect(select_expr.variants[0].default).to be_truthy

        # key02のメッセージを確認
        message = result.body.find {|entry| entry.is_a?(Foxtail::AST::Message) && entry.id.name == "key02" }
        expect(message).not_to be_nil
        expect(message.value).to be_a(Foxtail::AST::Pattern)
        expect(message.value.elements.size).to eq(1)
        expect(message.value.elements[0]).to be_a(Foxtail::AST::Placeable)
        expect(message.value.elements[0].expression).to be_a(Foxtail::AST::SelectExpression)

        # SelectExpressionの内容を確認
        select_expr = message.value.elements[0].expression
        expect(select_expr.selector).to be_a(Foxtail::AST::VariableReference)
        expect(select_expr.selector.id.name).to eq("sel")
        expect(select_expr.variants.size).to eq(1)
        expect(select_expr.variants[0].key.name).to eq("key")
        expect(select_expr.variants[0].default).to be_truthy
      end
    end
  end
end
