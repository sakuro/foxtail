# frozen_string_literal: true

RSpec.describe Foxtail::Parser do
  describe "#parse" do
    context "with literal expressions", ftl_fixture: "reference/literal_expressions" do
      include_examples "a valid FTL resource"
      it "correctly parses literal expressions" do
        # Verify that the body contains three messages
        expect(result.body.size).to eq(3)
        expect(result.body.all?(Foxtail::AST::Message)).to be true

        # Verify the string literal expression
        string_expr = result.body[0]
        expect(string_expr.id.name).to eq("string-expression")
        expect(string_expr.value).to be_a(Foxtail::AST::Pattern)
        expect(string_expr.value.elements.size).to eq(1)
        expect(string_expr.value.elements[0]).to be_a(Foxtail::AST::Placeable)

        string_literal = string_expr.value.elements[0].expression
        expect(string_literal).to be_a(Foxtail::AST::StringLiteral)
        expect(string_literal.value).to eq("abc")

        # Verify the first number literal expression (positive integer)
        number_expr1 = result.body[1]
        expect(number_expr1.id.name).to eq("number-expression")
        expect(number_expr1.value).to be_a(Foxtail::AST::Pattern)
        expect(number_expr1.value.elements.size).to eq(1)
        expect(number_expr1.value.elements[0]).to be_a(Foxtail::AST::Placeable)

        number_literal1 = number_expr1.value.elements[0].expression
        expect(number_literal1).to be_a(Foxtail::AST::NumberLiteral)
        expect(number_literal1.value).to eq("123")

        # Verify the second number literal expression (negative float)
        number_expr2 = result.body[2]
        expect(number_expr2.id.name).to eq("number-expression")
        expect(number_expr2.value).to be_a(Foxtail::AST::Pattern)
        expect(number_expr2.value.elements.size).to eq(1)
        expect(number_expr2.value.elements[0]).to be_a(Foxtail::AST::Placeable)

        number_literal2 = number_expr2.value.elements[0].expression
        expect(number_literal2).to be_a(Foxtail::AST::NumberLiteral)
        expect(number_literal2.value).to eq("-3.14")
      end
    end
  end
end
