# frozen_string_literal: true

require "spec_helper"

RSpec.describe Foxtail::Parser do
  describe "#parse" do
    context "with call expressions", ftl_fixture: "reference/call_expressions" do
      it "parses function calls correctly" do
        # Verify that the result is a Resource object
        expect(result).to be_a(Foxtail::AST::Resource)

        # Verify that the body contains multiple entries
        expect(result.body.size).to be > 1

        # Function call without arguments
        no_args = result.body.find {|entry|
          entry.is_a?(Foxtail::AST::Message) && entry.id.name == "valid-func-name-01"
        }
        expect(no_args).not_to be_nil
        expect(no_args.value).to be_a(Foxtail::AST::Pattern)
        expect(no_args.value.elements.size).to eq(1)
        expect(no_args.value.elements[0]).to be_a(Foxtail::AST::Placeable)
        expect(no_args.value.elements[0].expression).to be_a(Foxtail::AST::FunctionReference)
        expect(no_args.value.elements[0].expression.id.name).to eq("FUN1")
        expect(no_args.value.elements[0].expression.arguments).to be_a(Foxtail::AST::CallArguments)
        expect(no_args.value.elements[0].expression.arguments.positional).to be_empty
        expect(no_args.value.elements[0].expression.arguments.named).to be_empty

        # Function call with positional arguments
        positional_args = result.body.find {|entry|
          entry.is_a?(Foxtail::AST::Message) && entry.id.name == "positional-args"
        }
        expect(positional_args).not_to be_nil
        expect(positional_args.value).to be_a(Foxtail::AST::Pattern)
        expect(positional_args.value.elements.size).to eq(1)
        expect(positional_args.value.elements[0]).to be_a(Foxtail::AST::Placeable)
        expect(positional_args.value.elements[0].expression).to be_a(Foxtail::AST::FunctionReference)
        expect(positional_args.value.elements[0].expression.id.name).to eq("FUN")
        expect(positional_args.value.elements[0].expression.arguments).to be_a(Foxtail::AST::CallArguments)
        expect(positional_args.value.elements[0].expression.arguments.positional.size).to eq(3)
        expect(positional_args.value.elements[0].expression.arguments.positional[0]).to be_a(Foxtail::AST::NumberLiteral)
        expect(positional_args.value.elements[0].expression.arguments.positional[0].value).to eq("1")

        # Function call with named arguments
        named_args = result.body.find {|entry| entry.is_a?(Foxtail::AST::Message) && entry.id.name == "named-args" }
        expect(named_args).not_to be_nil
        expect(named_args.value).to be_a(Foxtail::AST::Pattern)
        expect(named_args.value.elements.size).to eq(1)
        expect(named_args.value.elements[0]).to be_a(Foxtail::AST::Placeable)
        expect(named_args.value.elements[0].expression).to be_a(Foxtail::AST::FunctionReference)
        expect(named_args.value.elements[0].expression.id.name).to eq("FUN")
        expect(named_args.value.elements[0].expression.arguments).to be_a(Foxtail::AST::CallArguments)
        expect(named_args.value.elements[0].expression.arguments.positional).to be_empty
        expect(named_args.value.elements[0].expression.arguments.named.size).to eq(2)
        expect(named_args.value.elements[0].expression.arguments.named[0]).to be_a(Foxtail::AST::NamedArgument)
        expect(named_args.value.elements[0].expression.arguments.named[0].name.name).to eq("x")
        expect(named_args.value.elements[0].expression.arguments.named[0].value).to be_a(Foxtail::AST::NumberLiteral)
        expect(named_args.value.elements[0].expression.arguments.named[0].value.value).to eq("1")

        # Function call with multiple arguments
        mixed_args = result.body.find {|entry| entry.is_a?(Foxtail::AST::Message) && entry.id.name == "mixed-args" }
        expect(mixed_args).not_to be_nil
        expect(mixed_args.value).to be_a(Foxtail::AST::Pattern)
        expect(mixed_args.value.elements.size).to eq(1)
        expect(mixed_args.value.elements[0]).to be_a(Foxtail::AST::Placeable)
        expect(mixed_args.value.elements[0].expression).to be_a(Foxtail::AST::FunctionReference)
        expect(mixed_args.value.elements[0].expression.id.name).to eq("FUN")
        expect(mixed_args.value.elements[0].expression.arguments).to be_a(Foxtail::AST::CallArguments)
        expect(mixed_args.value.elements[0].expression.arguments.positional.size).to eq(3)
        expect(mixed_args.value.elements[0].expression.arguments.positional[0]).to be_a(Foxtail::AST::NumberLiteral)
        expect(mixed_args.value.elements[0].expression.arguments.positional[0].value).to eq("1")
        expect(mixed_args.value.elements[0].expression.arguments.named.size).to eq(2)
        expect(mixed_args.value.elements[0].expression.arguments.named[0]).to be_a(Foxtail::AST::NamedArgument)
        expect(mixed_args.value.elements[0].expression.arguments.named[0].name.name).to eq("x")
        expect(mixed_args.value.elements[0].expression.arguments.named[0].value).to be_a(Foxtail::AST::NumberLiteral)
        expect(mixed_args.value.elements[0].expression.arguments.named[0].value.value).to eq("1")
      end
    end
  end
end
