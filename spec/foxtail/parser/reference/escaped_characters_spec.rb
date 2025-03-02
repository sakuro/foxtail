# frozen_string_literal: true

RSpec.describe Foxtail::Parser do
  describe "#parse" do
    context "with escaped characters", ftl_fixture: "reference/escaped_characters" do
      include_examples "a valid FTL resource"
      it "correctly parses escaped characters" do
        # The "Literal text" check
        skip "Group comments are not being parsed correctly"

        # Verify backslash in text
        text_backslash_one = find_message("text-backslash-one")
        expect(text_backslash_one).not_to be_nil
        expect(text_backslash_one.value).to be_a(Foxtail::AST::Pattern)
        expect(text_backslash_one.value.elements[0].value).to eq("Value with \\ a backslash")

        # Verify double backslash in text
        text_backslash_two = find_message("text-backslash-two")
        expect(text_backslash_two).not_to be_nil
        expect(text_backslash_two.value).to be_a(Foxtail::AST::Pattern)
        expect(text_backslash_two.value.elements[0].value).to eq("Value with \\\\ two backslashes")

        # Verify backslash before brace in text
        text_backslash_brace = find_message("text-backslash-brace")
        expect(text_backslash_brace).not_to be_nil
        expect(text_backslash_brace.value).to be_a(Foxtail::AST::Pattern)
        expect(text_backslash_brace.value.elements.size).to eq(2)
        expect(text_backslash_brace.value.elements[0].value).to eq("Value with \\")
        expect(text_backslash_brace.value.elements[1]).to be_a(Foxtail::AST::Placeable)
        expect(text_backslash_brace.value.elements[1].expression).to be_a(Foxtail::AST::MessageReference)
        expect(text_backslash_brace.value.elements[1].expression.id.name).to eq("placeable")

        # Verify backslash before u in text
        text_backslash_u = find_message("text-backslash-u")
        expect(text_backslash_u).not_to be_nil
        expect(text_backslash_u.value).to be_a(Foxtail::AST::Pattern)
        expect(text_backslash_u.value.elements[0].value).to eq("\\u0041")

        # Verify double backslash before u in text
        text_backslash_backslash_u = find_message("text-backslash-backslash-u")
        expect(text_backslash_backslash_u).not_to be_nil
        expect(text_backslash_backslash_u.value).to be_a(Foxtail::AST::Pattern)
        expect(text_backslash_backslash_u.value.elements[0].value).to eq("\\\\u0041")

        # The "String literals" group comment check
        skip "Group comments are not being parsed correctly"

        # Verify quote in string
        quote_in_string = find_message("quote-in-string")
        expect(quote_in_string).not_to be_nil
        expect(quote_in_string.value).to be_a(Foxtail::AST::Pattern)
        expect(quote_in_string.value.elements[0]).to be_a(Foxtail::AST::Placeable)
        expect(quote_in_string.value.elements[0].expression).to be_a(Foxtail::AST::StringLiteral)
        expect(quote_in_string.value.elements[0].expression.value).to eq("\\\"")

        # Verify backslash in string
        backslash_in_string = find_message("backslash-in-string")
        expect(backslash_in_string).not_to be_nil
        expect(backslash_in_string.value).to be_a(Foxtail::AST::Pattern)
        expect(backslash_in_string.value.elements[0]).to be_a(Foxtail::AST::Placeable)
        expect(backslash_in_string.value.elements[0].expression).to be_a(Foxtail::AST::StringLiteral)
        expect(backslash_in_string.value.elements[0].expression.value).to eq("\\\\")

        # Verify that invalid string literals are treated as Junk
        junk_entries = result.body.select {|entry| entry.is_a?(Foxtail::AST::Junk) }
        expect(junk_entries.size).to eq(5)

        # The "Unicode escapes" group comment check
        skip "Group comments are not being parsed correctly"

        # Verify unicode escape with 4 digits
        string_unicode_4digits = find_message("string-unicode-4digits")
        expect(string_unicode_4digits).not_to be_nil
        expect(string_unicode_4digits.value).to be_a(Foxtail::AST::Pattern)
        expect(string_unicode_4digits.value.elements[0]).to be_a(Foxtail::AST::Placeable)
        expect(string_unicode_4digits.value.elements[0].expression).to be_a(Foxtail::AST::StringLiteral)
        expect(string_unicode_4digits.value.elements[0].expression.value).to eq("\\u0041")

        # Verify escaped unicode escape with 4 digits
        escape_unicode_4digits = find_message("escape-unicode-4digits")
        expect(escape_unicode_4digits).not_to be_nil
        expect(escape_unicode_4digits.value).to be_a(Foxtail::AST::Pattern)
        expect(escape_unicode_4digits.value.elements[0]).to be_a(Foxtail::AST::Placeable)
        expect(escape_unicode_4digits.value.elements[0].expression).to be_a(Foxtail::AST::StringLiteral)
        expect(escape_unicode_4digits.value.elements[0].expression.value).to eq("\\\\u0041")

        # Verify unicode escape with 6 digits
        string_unicode_6digits = find_message("string-unicode-6digits")
        expect(string_unicode_6digits).not_to be_nil
        expect(string_unicode_6digits.value).to be_a(Foxtail::AST::Pattern)
        expect(string_unicode_6digits.value.elements[0]).to be_a(Foxtail::AST::Placeable)
        expect(string_unicode_6digits.value.elements[0].expression).to be_a(Foxtail::AST::StringLiteral)
        expect(string_unicode_6digits.value.elements[0].expression.value).to eq("\\U01F602")

        # Verify escaped unicode escape with 6 digits
        escape_unicode_6digits = find_message("escape-unicode-6digits")
        expect(escape_unicode_6digits).not_to be_nil
        expect(escape_unicode_6digits.value).to be_a(Foxtail::AST::Pattern)
        expect(escape_unicode_6digits.value.elements[0]).to be_a(Foxtail::AST::Placeable)
        expect(escape_unicode_6digits.value.elements[0].expression).to be_a(Foxtail::AST::StringLiteral)
        expect(escape_unicode_6digits.value.elements[0].expression.value).to eq("\\\\U01F602")

        # Verify unicode escape with too many digits (4)
        string_too_many_4digits = find_message("string-too-many-4digits")
        expect(string_too_many_4digits).not_to be_nil
        expect(string_too_many_4digits.value).to be_a(Foxtail::AST::Pattern)
        expect(string_too_many_4digits.value.elements[0]).to be_a(Foxtail::AST::Placeable)
        expect(string_too_many_4digits.value.elements[0].expression).to be_a(Foxtail::AST::StringLiteral)
        expect(string_too_many_4digits.value.elements[0].expression.value).to eq("\\u004100")
        expect(string_too_many_4digits.comment).not_to be_nil
        expect(string_too_many_4digits.comment.content).to eq("OK The trailing \"00\" is part of the literal value.")

        # Verify unicode escape with too many digits (6)
        string_too_many_6digits = find_message("string-too-many-6digits")
        expect(string_too_many_6digits).not_to be_nil
        expect(string_too_many_6digits.value).to be_a(Foxtail::AST::Pattern)
        expect(string_too_many_6digits.value.elements[0]).to be_a(Foxtail::AST::Placeable)
        expect(string_too_many_6digits.value.elements[0].expression).to be_a(Foxtail::AST::StringLiteral)
        expect(string_too_many_6digits.value.elements[0].expression.value).to eq("\\U01F60200")
        expect(string_too_many_6digits.comment).not_to be_nil
        expect(string_too_many_6digits.comment.content).to eq("OK The trailing \"00\" is part of the literal value.")

        # The "Literal braces" group comment check
        skip "Group comments are not being parsed correctly"

        # Verify literal open brace
        brace_open = find_message("brace-open")
        expect(brace_open).not_to be_nil
        expect(brace_open.value).to be_a(Foxtail::AST::Pattern)
        expect(brace_open.value.elements.size).to eq(3)
        expect(brace_open.value.elements[0].value).to eq("An opening ")
        expect(brace_open.value.elements[1]).to be_a(Foxtail::AST::Placeable)
        expect(brace_open.value.elements[1].expression).to be_a(Foxtail::AST::StringLiteral)
        expect(brace_open.value.elements[1].expression.value).to eq("{")
        expect(brace_open.value.elements[2].value).to eq(" brace.")

        # Verify literal close brace
        brace_close = find_message("brace-close")
        expect(brace_close).not_to be_nil
        expect(brace_close.value).to be_a(Foxtail::AST::Pattern)
        expect(brace_close.value.elements.size).to eq(3)
        expect(brace_close.value.elements[0].value).to eq("A closing ")
        expect(brace_close.value.elements[1]).to be_a(Foxtail::AST::Placeable)
        expect(brace_close.value.elements[1].expression).to be_a(Foxtail::AST::StringLiteral)
        expect(brace_close.value.elements[1].expression.value).to eq("}")
        expect(brace_close.value.elements[2].value).to eq(" brace.")
      end
    end
  end
end
