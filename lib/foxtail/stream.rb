# frozen_string_literal: true

module Foxtail
  # Base class for parser streams
  class ParserStream
    attr_reader :string
    attr_reader :index
    attr_reader :peek_offset

    def initialize(string)
      @string = string
      @index = 0
      @peek_offset = 0
    end

    def char_at(offset)
      # 文字列の範囲外の場合はEOFを返す
      return EOF if offset.nil? || offset < 0 || offset >= @string.length

      # When the cursor is at CRLF, return LF but don't move the cursor.
      # The cursor still points to the EOL position, which in this case is the
      # beginning of the compound CRLF sequence. This ensures slices of
      # [inclusive, exclusive) continue to work properly.
      if @string[offset] == "\r" && offset + 1 < @string.length &&
         @string[offset + 1] == "\n"

        return "\n"
      end

      @string[offset]
    end

    def current_char
      char_at(@index)
    end

    def current_peek
      char_at(@index + @peek_offset)
    end

    def next_char
      @peek_offset = 0
      # Skip over the CRLF as if it was a single character.
      if @index < @string.length && @string[@index] == "\r" &&
         @index + 1 < @string.length && @string[@index + 1] == "\n"

        @index += 1
      end
      @index += 1
      char_at(@index)
    end

    def peek
      # Skip over the CRLF as if it was a single character.
      peek_index = @index + @peek_offset
      if peek_index < @string.length && @string[peek_index] == "\r" &&
         peek_index + 1 < @string.length && @string[peek_index + 1] == "\n"

        @peek_offset += 1
      end
      @peek_offset += 1
      char_at(@index + @peek_offset)
    end

    def reset_peek(offset=0)
      @peek_offset = offset
    end

    def skip_to_peek
      @index += @peek_offset
      @peek_offset = 0
    end
  end

  # Constants for parser stream
  EOL = "\n"
  private_constant :EOL

  EOF = nil
  private_constant :EOF

  SPECIAL_LINE_START_CHARS = ["}", ".", "[", "*"].freeze
  private_constant :SPECIAL_LINE_START_CHARS

  # Fluent parser stream
  class FluentParserStream < ParserStream
    def peek_blank_inline
      start = @index + @peek_offset
      peek while current_peek == " "
      @string[start...(@index + @peek_offset)]
    end

    def skip_blank_inline
      blank = peek_blank_inline
      skip_to_peek
      blank
    end

    def peek_blank_block
      blank = ""
      loop do
        line_start = @peek_offset
        peek_blank_inline
        if current_peek == EOL
          blank += EOL
          peek
          next
        end
        if current_peek == EOF
          # Treat the blank line at EOF as a blank block.
          return blank
        end

        # Any other char; reset to column 1 on this line.
        reset_peek(line_start)
        return blank
      end
    end

    def skip_blank_block
      blank = peek_blank_block
      skip_to_peek
      blank
    end

    def peek_blank
      peek while current_peek == " " || current_peek == EOL
    end

    def skip_blank
      peek_blank
      skip_to_peek
    end

    def expect_char(ch)
      if current_char == ch
        next_char
        return
      end

      raise Errors::ParseError.new("E0003", ch)
    end

    def expect_line_end
      if current_char == EOF
        # EOF is a valid line end in Fluent.
        return
      end

      if current_char == EOL
        next_char
        return
      end

      # Unicode Character 'SYMBOL FOR NEWLINE' (U+2424)
      raise Errors::ParseError.new("E0003", "\u2424")
    end

    def take_char(predicate)
      ch = current_char
      return EOF if ch == EOF
      return nil unless predicate.call(ch)

      next_char
      ch
    end

    def char_id_start?(ch)
      return false if ch == EOF

      ch =~ /[a-zA-Z]/
    end

    def identifier_start?
      char_id_start?(current_peek)
    end

    def number_start?
      ch = current_char == "-" ? peek : current_char

      if ch == EOF
        reset_peek
        return false
      end

      is_digit = ch =~ /[0-9]/
      reset_peek
      is_digit
    end

    def char_pattern_continuation?(ch)
      return false if ch == EOF

      !SPECIAL_LINE_START_CHARS.include?(ch)
    end

    def value_start?
      # Inline Patterns may start with any char.
      ch = current_peek
      ch != EOL && ch != EOF
    end

    def value_continuation?
      column1 = @peek_offset
      peek_blank_inline

      if current_peek == "{"
        reset_peek(column1)
        return true
      end

      if @peek_offset - column1 == 0
        return false
      end

      if char_pattern_continuation?(current_peek)
        reset_peek(column1)
        return true
      end

      false
    end

    def next_line_comment?(level=-1)
      return false if current_char != EOL

      # 次の行の先頭に#があるか確認
      next_char = peek
      if next_char != "#"
        reset_peek
        return false
      end

      # #の数をカウント
      i = 1
      while i <= level || (level == -1 && i < 3)
        if peek != "#"
          if i <= level && level != -1
            reset_peek
            return false
          end
          break
        end
        i += 1
      end

      # The first char after #, ## or ###.
      ch = peek
      if ch == " " || ch == EOL
        reset_peek
        return true
      end

      reset_peek
      false
    end

    def variant_start?
      current_peek_offset = @peek_offset
      if current_peek == "*"
        peek
      end
      if current_peek == "["
        reset_peek(current_peek_offset)
        return true
      end
      reset_peek(current_peek_offset)
      false
    end

    def attribute_start?
      current_peek == "."
    end

    def skip_to_next_entry_start(junk_start)
      last_newline = @string.rindex(EOL, @index)
      if last_newline && junk_start < last_newline
        # Last seen newline is _after_ the junk start. It's safe to rewind
        # without the risk of resuming at the same broken entry.
        @index = last_newline
      end
      while current_char
        # We're only interested in beginnings of line.
        if current_char != EOL
          next_char
          next
        end

        # Break if the first char in this line looks like an entry start.
        first = next_char
        if char_id_start?(first) || first == "-" || first == "#"
          break
        end
      end
    end

    def take_id_start
      if char_id_start?(current_char)
        ret = current_char
        next_char
        return ret
      end

      raise Errors::ParseError.new("E0004", "a-zA-Z")
    end

    def take_id_char
      take_char ->(ch) { ch =~ /[a-zA-Z0-9_-]/ }
    end

    def take_digit
      take_char ->(ch) { ch =~ /[0-9]/ }
    end

    def take_hex_digit
      take_char ->(ch) { ch =~ /[0-9A-Fa-f]/ }
    end
  end
end
