# frozen_string_literal: true

RSpec.describe Foxtail::Parser do
  describe "#parse" do
    context "with callee expressions", ftl_fixture: "reference/callee_expressions" do
      include_examples "a valid FTL resource"
      it "correctly parses callee expressions" do
        # Verify the GroupComment
        expect(result.body[0]).to be_a(Foxtail::AST::GroupComment)
        expect(result.body[0].content).to eq("Callees in placeables.")

        # Verify the function callee in placeable
        function_callee_placeable = result.body[1]
        expect(function_callee_placeable).to be_a(Foxtail::AST::Message)
        expect(function_callee_placeable.id.name).to eq("function-callee-placeable")

        placeable = function_callee_placeable.value.elements[0]
        expect(placeable).to be_a(Foxtail::AST::Placeable)

        function_ref = placeable.expression
        expect(function_ref).to be_a(Foxtail::AST::FunctionReference)
        expect(function_ref.id.name).to eq("FUNCTION")
        expect(function_ref.arguments).to be_a(Foxtail::AST::CallArguments)
        expect(function_ref.arguments.positional).to be_empty
        expect(function_ref.arguments.named).to be_empty

        # Verify the term callee in placeable
        term_callee_placeable = result.body[2]
        expect(term_callee_placeable).to be_a(Foxtail::AST::Message)
        expect(term_callee_placeable.id.name).to eq("term-callee-placeable")

        placeable = term_callee_placeable.value.elements[0]
        expect(placeable).to be_a(Foxtail::AST::Placeable)

        term_ref = placeable.expression
        expect(term_ref).to be_a(Foxtail::AST::TermReference)
        expect(term_ref.id.name).to eq("term")
        expect(term_ref.attribute).to be_nil
        expect(term_ref.arguments).to be_a(Foxtail::AST::CallArguments)
        expect(term_ref.arguments.positional).to be_empty
        expect(term_ref.arguments.named).to be_empty

        # Verify that invalid callees are treated as Junk
        junk_entries = result.body.select {|entry| entry.is_a?(Foxtail::AST::Junk) }
        expect(junk_entries.size).to eq(10)

        # Verify that each Junk entry contains the expected content
        expect(junk_entries[0].content).to include("message-callee-placeable = {message()}")
        expect(junk_entries[1].content).to include("mixed-case-callee-placeable = {Function()}")
        expect(junk_entries[2].content).to include("message-attr-callee-placeable = {message.attr()}")
        expect(junk_entries[3].content).to include("term-attr-callee-placeable = {-term.attr()}")
        expect(junk_entries[4].content).to include("variable-callee-placeable = {$variable()}")

        # Verify the second GroupComment
        group_comment = result.body.find {|entry|
          entry.is_a?(Foxtail::AST::GroupComment) && entry.content == "Callees in selectors."
        }
        expect(group_comment).not_to be_nil

        # Verify the function callee in selector
        function_callee_selector = result.body.find {|entry|
          entry.is_a?(Foxtail::AST::Message) && entry.id.name == "function-callee-selector"
        }
        expect(function_callee_selector).not_to be_nil

        placeable = function_callee_selector.value.elements[0]
        expect(placeable).to be_a(Foxtail::AST::Placeable)

        select_expr = placeable.expression
        expect(select_expr).to be_a(Foxtail::AST::SelectExpression)

        selector = select_expr.selector
        expect(selector).to be_a(Foxtail::AST::FunctionReference)
        expect(selector.id.name).to eq("FUNCTION")
        expect(selector.arguments).to be_a(Foxtail::AST::CallArguments)
        expect(selector.arguments.positional).to be_empty
        expect(selector.arguments.named).to be_empty

        # Verify the term attribute callee in selector
        term_attr_callee_selector = result.body.find {|entry|
          entry.is_a?(Foxtail::AST::Message) && entry.id.name == "term-attr-callee-selector"
        }
        expect(term_attr_callee_selector).not_to be_nil

        placeable = term_attr_callee_selector.value.elements[0]
        expect(placeable).to be_a(Foxtail::AST::Placeable)

        select_expr = placeable.expression
        expect(select_expr).to be_a(Foxtail::AST::SelectExpression)

        selector = select_expr.selector
        expect(selector).to be_a(Foxtail::AST::TermReference)
        expect(selector.id.name).to eq("term")
        expect(selector.attribute).not_to be_nil
        expect(selector.attribute.name).to eq("attr")
        expect(selector.arguments).to be_a(Foxtail::AST::CallArguments)
        expect(selector.arguments.positional).to be_empty
        expect(selector.arguments.named).to be_empty
      end
    end
  end
end
