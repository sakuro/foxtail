# frozen_string_literal: true

RSpec.describe Foxtail::Parser do
  describe "#parse" do
    context "with member expressions", ftl_fixture: "reference/member_expressions" do
      include_examples "a valid FTL resource"
      it "correctly parses member expressions" do
        # Verify the first GroupComment
        expect(result.body[0]).to be_a(Foxtail::AST::GroupComment)
        expect(result.body[0].content).to eq("Member expressions in placeables.")

        # Verify the message attribute expression in placeable
        message_attr_expr = result.body[1]
        expect(message_attr_expr).to be_a(Foxtail::AST::Message)
        expect(message_attr_expr.id.name).to eq("message-attribute-expression-placeable")
        expect(message_attr_expr.comment).not_to be_nil
        expect(message_attr_expr.comment.content).to eq("OK Message attributes may be interpolated in values.")

        placeable = message_attr_expr.value.elements[0]
        expect(placeable).to be_a(Foxtail::AST::Placeable)

        message_ref = placeable.expression
        expect(message_ref).to be_a(Foxtail::AST::MessageReference)
        expect(message_ref.id.name).to eq("msg")
        expect(message_ref.attribute).not_to be_nil
        expect(message_ref.attribute.name).to eq("attr")

        # Verify that term attribute expression in placeable is treated as Junk
        expect(result.body[2]).to be_a(Foxtail::AST::Comment)
        expect(result.body[2].content).to eq("ERROR Term attributes may not be used for interpolation.")

        expect(result.body[3]).to be_a(Foxtail::AST::Junk)
        expect(result.body[3].content).to include("term-attribute-expression-placeable = {-term.attr}")

        # Verify the second GroupComment
        expect(result.body[4]).to be_a(Foxtail::AST::GroupComment)
        expect(result.body[4].content).to eq("Member expressions in selectors.")

        # Verify the term attribute expression in selector
        term_attr_expr = result.body[5]
        expect(term_attr_expr).to be_a(Foxtail::AST::Message)
        expect(term_attr_expr.id.name).to eq("term-attribute-expression-selector")
        expect(term_attr_expr.comment).not_to be_nil
        expect(term_attr_expr.comment.content).to eq("OK Term attributes may be used as selectors.")

        placeable = term_attr_expr.value.elements[0]
        expect(placeable).to be_a(Foxtail::AST::Placeable)

        select_expr = placeable.expression
        expect(select_expr).to be_a(Foxtail::AST::SelectExpression)

        selector = select_expr.selector
        expect(selector).to be_a(Foxtail::AST::TermReference)
        expect(selector.id.name).to eq("term")
        expect(selector.attribute).not_to be_nil
        expect(selector.attribute.name).to eq("attr")
        expect(selector.arguments).to be_nil

        # Verify that message attribute expression in selector is treated as Junk
        expect(result.body[6]).to be_a(Foxtail::AST::Comment)
        expect(result.body[6].content).to eq("ERROR Message attributes may not be used as selectors.")

        expect(result.body[7]).to be_a(Foxtail::AST::Junk)
        expect(result.body[7].content).to include("message-attribute-expression-selector = {msg.attr ->")
      end
    end
  end
end
