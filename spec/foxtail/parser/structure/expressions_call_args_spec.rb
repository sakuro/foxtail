# frozen_string_literal: true

RSpec.describe Foxtail::Parser do
  describe "#parse" do
    context "with expressions call args", ftl_fixture: "structure/expressions_call_args" do
      include_examples "a valid FTL resource"
      it "parses multiline call arguments correctly" do
        # Verify that the body contains one Message
        expect(result.body.size).to eq(1)
        expect(result.body[0]).to be_a(Foxtail::AST::Message)

        # Verify the Message content
        message = result.body[0]
        expect(message.id.name).to eq("key")
        expect(message.value).to be_a(Foxtail::AST::Pattern)
        expect(message.value.elements.size).to eq(1)
        expect(message.value.elements[0]).to be_a(Foxtail::AST::Placeable)

        # Verify the Placeable content
        placeable = message.value.elements[0]
        expect(placeable.expression).to be_a(Foxtail::AST::FunctionReference)
        expect(placeable.expression.id.name).to eq("FOO")

        # Verify the CallArguments content
        call_args = placeable.expression.arguments
        expect(call_args).to be_a(Foxtail::AST::CallArguments)
        expect(call_args.positional).to be_empty
        expect(call_args.named.size).to eq(2)

        # Verify the first named argument
        expect(call_args.named[0]).to be_a(Foxtail::AST::NamedArgument)
        expect(call_args.named[0].name.name).to eq("arg1")
        expect(call_args.named[0].value).to be_a(Foxtail::AST::NumberLiteral)
        expect(call_args.named[0].value.value).to eq("1")

        # Verify the second named argument
        expect(call_args.named[1]).to be_a(Foxtail::AST::NamedArgument)
        expect(call_args.named[1].name.name).to eq("arg2")
        expect(call_args.named[1].value).to be_a(Foxtail::AST::NumberLiteral)
        expect(call_args.named[1].value.value).to eq("2")
      end
    end
  end
end
