# frozen_string_literal: true

module Foxtail
  # Ruby equivalent of fluent.js FluentParserStream
  # Handles character stream processing with CRLF normalization and parsing utilities
  class Stream
    # Constants
    EOL = "\n"
    EOF = nil
    SPECIAL_LINE_START_CHARS = ["}", ".", "[", "*"].freeze

    attr_reader :string, :index, :peek_offset

    def initialize(string)
      @string = string
      @index = 0
      @peek_offset = 0
    end

    # Base stream methods (from ParserStream)

    def char_at(offset)
      # When the cursor is at CRLF, return LF but don't move the cursor.
      # The cursor still points to the EOL position, which in this case is the
      # beginning of the compound CRLF sequence. This ensures slices of
      # [inclusive, exclusive) continue to work properly.
      if @string[offset] == "\r" && @string[offset + 1] == "\n"
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

    def next
      @peek_offset = 0
      # Skip over the CRLF as if it was a single character.
      if @string[@index] == "\r" && @string[@index + 1] == "\n"
        @index += 1
      end
      @index += 1
      @string[@index]
    end

    def peek
      # Skip over the CRLF as if it was a single character.
      if @string[@index + @peek_offset] == "\r" && @string[@index + @peek_offset + 1] == "\n"
        @peek_offset += 1
      end
      @peek_offset += 1
      @string[@index + @peek_offset]
    end

    def reset_peek(offset = 0)
      @peek_offset = offset
    end

    def skip_to_peek
      @index += @peek_offset
      @peek_offset = 0
    end

    # FluentParserStream methods

    def peek_blank_inline
      start = @index + @peek_offset
      while current_peek == " "
        peek
      end
      @string.slice(start, @index + @peek_offset - start)
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
      while current_peek == " " || current_peek == EOL
        peek
      end
    end

    def skip_blank
      peek_blank
      skip_to_peek
    end

    def expect_char(ch)
      if current_char == ch
        self.next
        return
      end

      raise ParseError.new("E0003", ch)
    end

    def expect_line_end
      if current_char == EOF
        # EOF is a valid line end in Fluent.
        return
      end

      if current_char == EOL
        self.next
        return
      end

      # Unicode Character 'SYMBOL FOR NEWLINE' (U+2424)
      raise ParseError.new("E0003", "\u2424")
    end

    def take_char(&block)
      ch = current_char
      if ch == EOF
        return EOF
      end
      if block.call(ch)
        self.next
        return ch
      end
      nil
    end

    def char_id_start?(ch)
      return false if ch == EOF

      cc = ch.ord
      (cc >= 97 && cc <= 122) || # a-z
        (cc >= 65 && cc <= 90)    # A-Z
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

      cc = ch.ord
      is_digit = cc >= 48 && cc <= 57 # 0-9
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

    # @param level - -1: any, 0: comment, 1: group comment, 2: resource comment
    def next_line_comment?(level = -1)
      return false if current_char != EOL

      i = 0

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
        unless current_char == EOL
          self.next
          next
        end

        # Break if the first char in this line looks like an entry start.
        first = self.next
        if char_id_start?(first) || first == "-" || first == "#"
          break
        end
      end
    end

    def take_id_start
      if char_id_start?(current_char)
        ret = current_char
        self.next
        return ret
      end

      raise ParseError.new("E0004", "a-zA-Z")
    end

    def take_id_char
      take_char do |ch|
        cc = ch.ord
        (cc >= 97 && cc <= 122) || # a-z
          (cc >= 65 && cc <= 90) ||  # A-Z
          (cc >= 48 && cc <= 57) ||  # 0-9
          cc == 95 ||                # _
          cc == 45                   # -
      end
    end

    def take_digit
      take_char do |ch|
        cc = ch.ord
        cc >= 48 && cc <= 57 # 0-9
      end
    end

    def take_hex_digit
      take_char do |ch|
        cc = ch.ord
        (cc >= 48 && cc <= 57) || # 0-9
          (cc >= 65 && cc <= 70) ||  # A-F
          (cc >= 97 && cc <= 102)    # a-f
      end
    end
  end
end