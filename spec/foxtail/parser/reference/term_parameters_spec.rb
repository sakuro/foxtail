# frozen_string_literal: true

require "spec_helper"

RSpec.describe Foxtail::Parser do
  describe "#parse" do
    context "with term parameters", ftl_fixture: "reference/term_parameters" do
      it "parses term parameters correctly" do
        # Verify that the result is a Resource object
        expect(result).to be_a(Foxtail::AST::Resource)

        # Verify that the body contains multiple entries
        expect(result.body.size).to be > 1

        # Verify the term definition
        term = result.body.find {|entry| entry.is_a?(Foxtail::AST::Term) && entry.id.name == "term" }
        expect(term).not_to be_nil
        expect(term.value).to be_a(Foxtail::AST::Pattern)
        expect(term.value.elements.size).to eq(1)
        expect(term.value.elements[0]).to be_a(Foxtail::AST::Placeable)
        expect(term.value.elements[0].expression).to be_a(Foxtail::AST::SelectExpression)

        # Verify the SelectExpression content
        select_expr = term.value.elements[0].expression
        expect(select_expr.selector).to be_a(Foxtail::AST::VariableReference)
        expect(select_expr.selector.id.name).to eq("arg")

        # Verify the Variants content
        expect(select_expr.variants.size).to eq(1)
        expect(select_expr.variants[0]).to be_a(Foxtail::AST::Variant)
        expect(select_expr.variants[0].key.name).to eq("key")
        expect(select_expr.variants[0].value).to be_a(Foxtail::AST::Pattern)
        expect(select_expr.variants[0].value.elements[0]).to be_a(Foxtail::AST::TextElement)
        expect(select_expr.variants[0].value.elements[0].value).to eq("Value")

        # Term reference without arguments
        no_args = result.body.find {|entry| entry.is_a?(Foxtail::AST::Message) && entry.id.name == "key01" }
        expect(no_args).not_to be_nil
        expect(no_args.value).to be_a(Foxtail::AST::Pattern)
        expect(no_args.value.elements.size).to eq(1)
        expect(no_args.value.elements[0]).to be_a(Foxtail::AST::Placeable)
        expect(no_args.value.elements[0].expression).to be_a(Foxtail::AST::TermReference)
        expect(no_args.value.elements[0].expression.id.name).to eq("term")
        expect(no_args.value.elements[0].expression.arguments).to be_nil.or be_empty

        # Term reference with empty parentheses
        empty_args = result.body.find {|entry| entry.is_a?(Foxtail::AST::Message) && entry.id.name == "key02" }
        expect(empty_args).not_to be_nil
        expect(empty_args.value).to be_a(Foxtail::AST::Pattern)
        expect(empty_args.value.elements.size).to eq(1)
        expect(empty_args.value.elements[0]).to be_a(Foxtail::AST::Placeable)
        expect(empty_args.value.elements[0].expression).to be_a(Foxtail::AST::TermReference)
        expect(empty_args.value.elements[0].expression.id.name).to eq("term")
        expect(empty_args.value.elements[0].expression.arguments).to be_a(Foxtail::AST::CallArguments)
        expect(empty_args.value.elements[0].expression.arguments.positional).to be_empty
        expect(empty_args.value.elements[0].expression.arguments.named).to be_empty

        # Term reference with arguments
        with_args = result.body.find {|entry| entry.is_a?(Foxtail::AST::Message) && entry.id.name == "key03" }
        expect(with_args).not_to be_nil
        expect(with_args.value).to be_a(Foxtail::AST::Pattern)
        expect(with_args.value.elements.size).to eq(1)
        expect(with_args.value.elements[0]).to be_a(Foxtail::AST::Placeable)
        expect(with_args.value.elements[0].expression).to be_a(Foxtail::AST::TermReference)
        expect(with_args.value.elements[0].expression.id.name).to eq("term")
        expect(with_args.value.elements[0].expression.arguments).to be_a(Foxtail::AST::CallArguments)
        expect(with_args.value.elements[0].expression.arguments.positional).to be_empty
        expect(with_args.value.elements[0].expression.arguments.named.size).to eq(1)
        expect(with_args.value.elements[0].expression.arguments.named[0]).to be_a(Foxtail::AST::NamedArgument)
        expect(with_args.value.elements[0].expression.arguments.named[0].name.name).to eq("arg")
        expect(with_args.value.elements[0].expression.arguments.named[0].value).to be_a(Foxtail::AST::NumberLiteral)
        expect(with_args.value.elements[0].expression.arguments.named[0].value.value).to eq("1")

        # Term reference with multiple arguments
        mixed_args = result.body.find {|entry| entry.is_a?(Foxtail::AST::Message) && entry.id.name == "key04" }
        expect(mixed_args).not_to be_nil
        expect(mixed_args.value).to be_a(Foxtail::AST::Pattern)
        expect(mixed_args.value.elements.size).to eq(1)
        expect(mixed_args.value.elements[0]).to be_a(Foxtail::AST::Placeable)
        expect(mixed_args.value.elements[0].expression).to be_a(Foxtail::AST::TermReference)
        expect(mixed_args.value.elements[0].expression.id.name).to eq("term")
        expect(mixed_args.value.elements[0].expression.arguments).to be_a(Foxtail::AST::CallArguments)

        # Positional arguments
        expect(mixed_args.value.elements[0].expression.arguments.positional.size).to eq(1)
        expect(mixed_args.value.elements[0].expression.arguments.positional[0]).to be_a(Foxtail::AST::StringLiteral)
        expect(mixed_args.value.elements[0].expression.arguments.positional[0].value).to eq("positional")

        # Named arguments
        expect(mixed_args.value.elements[0].expression.arguments.named.size).to eq(2)

        # Named argument 1
        expect(mixed_args.value.elements[0].expression.arguments.named[0]).to be_a(Foxtail::AST::NamedArgument)
        expect(mixed_args.value.elements[0].expression.arguments.named[0].name.name).to eq("narg1")
        expect(mixed_args.value.elements[0].expression.arguments.named[0].value).to be_a(Foxtail::AST::NumberLiteral)
        expect(mixed_args.value.elements[0].expression.arguments.named[0].value.value).to eq("1")

        # Named argument 2
        expect(mixed_args.value.elements[0].expression.arguments.named[1]).to be_a(Foxtail::AST::NamedArgument)
        expect(mixed_args.value.elements[0].expression.arguments.named[1].name.name).to eq("narg2")
        expect(mixed_args.value.elements[0].expression.arguments.named[1].value).to be_a(Foxtail::AST::NumberLiteral)
        expect(mixed_args.value.elements[0].expression.arguments.named[1].value.value).to eq("2")
      end
    end
  end
end
