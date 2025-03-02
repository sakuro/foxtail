# frozen_string_literal: true

RSpec.describe Foxtail::Parser do
  describe "#parse" do
    context "with reference expressions", ftl_fixture: "reference/reference_expressions" do
      include_examples "a valid FTL resource"
      it "parses message and term references correctly" do
        # Verify that the body contains multiple entries
        expect(result.body.size).to be > 1

        # Test message reference
        message_ref = result.body.find {|entry|
          entry.is_a?(Foxtail::AST::Message) && entry.id.name == "message-reference-placeable"
        }
        expect(message_ref).not_to be_nil
        expect(message_ref.value).to be_a(Foxtail::AST::Pattern)
        expect(message_ref.value.elements.size).to eq(1)
        expect(message_ref.value.elements[0]).to be_a(Foxtail::AST::Placeable)
        expect(message_ref.value.elements[0].expression).to be_a(Foxtail::AST::MessageReference)
        expect(message_ref.value.elements[0].expression.id.name).to eq("msg")

        # Test variable reference
        var_ref = result.body.find {|entry|
          entry.is_a?(Foxtail::AST::Message) && entry.id.name == "variable-reference-placeable"
        }
        expect(var_ref).not_to be_nil
        expect(var_ref.value).to be_a(Foxtail::AST::Pattern)
        expect(var_ref.value.elements.size).to eq(1)
        expect(var_ref.value.elements[0]).to be_a(Foxtail::AST::Placeable)
        expect(var_ref.value.elements[0].expression).to be_a(Foxtail::AST::VariableReference)
        expect(var_ref.value.elements[0].expression.id.name).to eq("var")

        # Test term reference
        term_ref = result.body.find {|entry|
          entry.is_a?(Foxtail::AST::Message) && entry.id.name == "term-reference-placeable"
        }
        expect(term_ref).not_to be_nil
        expect(term_ref.value).to be_a(Foxtail::AST::Pattern)
        expect(term_ref.value.elements.size).to eq(1)
        expect(term_ref.value.elements[0]).to be_a(Foxtail::AST::Placeable)
        expect(term_ref.value.elements[0].expression).to be_a(Foxtail::AST::TermReference)
        expect(term_ref.value.elements[0].expression.id.name).to eq("term")

        # Test function reference (parsed as MessageReference)
        func_ref = result.body.find {|entry|
          entry.is_a?(Foxtail::AST::Message) && entry.id.name == "function-reference-placeable"
        }
        expect(func_ref).not_to be_nil
        expect(func_ref.value).to be_a(Foxtail::AST::Pattern)
        expect(func_ref.value.elements.size).to eq(1)
        expect(func_ref.value.elements[0]).to be_a(Foxtail::AST::Placeable)
        expect(func_ref.value.elements[0].expression).to be_a(Foxtail::AST::MessageReference)
        expect(func_ref.value.elements[0].expression.id.name).to eq("FUN")
      end
    end
  end
end
