# frozen_string_literal: true

module Foxtail
  module Syntax
    class Parser
      module AST
      # Represents quoted string literals with escape sequence processing
      class StringLiteral < BaseLiteral
        # Parse the string literal value, processing escape sequences
        # Handles backslash escapes, Unicode escapes (uHHHH, UHHHHHH), and validates Unicode scalar values
        # @return [Hash] Hash containing the parsed string value
        def parse
          # Backslash backslash, backslash double quote, uHHHH, UHHHHHH.
          known_escapes = /(?:\\\\|\\"|\\u([0-9a-fA-F]{4})|\\U([0-9a-fA-F]{6}))/

          escaped_value = @value.gsub(known_escapes) {|match|
            codepoint4 = $1
            codepoint6 = $2

            case match
            when "\\\\"
              "\\"
            when '\\"'
              '"'
            else
              codepoint = (codepoint4 || codepoint6).to_i(16)
              if codepoint <= 0xd7ff || 0xe000 <= codepoint
                # It's a Unicode scalar value.
                codepoint.chr(Encoding::UTF_8)
              else
                # Escape sequences representing surrogate code points are
                # well-formed but invalid in Fluent. Replace them with U+FFFD
                # REPLACEMENT CHARACTER.
                "\uFFFD"
              end
            end
          }

          {value: escaped_value}
        end
      end
    end
  end
end
end
