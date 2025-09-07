# frozen_string_literal: true

require "spec_helper"

RSpec.describe Foxtail::Parser::Stream do
  describe "basic functionality" do
    let(:stream) { Foxtail::Parser::Stream.new("hello world") }

    it "initializes correctly" do
      expect(stream.string).to eq("hello world")
      expect(stream.index).to eq(0)
      expect(stream.peek_offset).to eq(0)
    end

    it "handles current_char" do
      expect(stream.current_char).to eq("h")
    end

    it "handles next" do
      expect(stream.next).to eq("e")
      expect(stream.index).to eq(1)
      expect(stream.current_char).to eq("e")
    end

    it "handles peek" do
      expect(stream.current_peek).to eq("h")
      expect(stream.peek).to eq("e")
      expect(stream.index).to eq(0) # index doesn't move
      expect(stream.peek_offset).to eq(1)
      expect(stream.current_peek).to eq("e")
    end

    it "handles reset_peek" do
      stream.peek
      stream.peek
      expect(stream.peek_offset).to eq(2)
      stream.reset_peek
      expect(stream.peek_offset).to eq(0)
    end

    it "handles skip_to_peek" do
      stream.peek
      stream.peek
      expect(stream.index).to eq(0)
      expect(stream.peek_offset).to eq(2)
      stream.skip_to_peek
      expect(stream.index).to eq(2)
      expect(stream.peek_offset).to eq(0)
    end
  end

  describe "CRLF handling" do
    let(:stream) { Foxtail::Parser::Stream.new("line1\r\nline2\nline3") }

    it "normalizes CRLF to LF in char_at" do
      expect(stream.char_at(5)).to eq("\n") # Should return \n for \r in CRLF
      expect(stream.char_at(6)).to eq("\n") # Should return \n for \n in CRLF
    end

    it "skips over CRLF in next" do
      5.times { stream.next } # Move to the \r in \r\n
      expect(stream.current_char).to eq("\n")
      stream.next # Should skip both \r and \n
      expect(stream.current_char).to eq("l") # Should be on 'l' of 'line2'
    end

    it "skips over CRLF in peek" do
      5.times { stream.peek } # Peek to the \r in \r\n
      expect(stream.current_peek).to eq("\n")
      stream.peek # Should skip both \r and \n
      expect(stream.current_peek).to eq("l") # Should be on 'l' of 'line2'
    end
  end

  describe "blank handling" do
    let(:stream) { Foxtail::Parser::Stream.new("  hello   \n  world") }

    it "handles peek_blank_inline" do
      blank = stream.peek_blank_inline
      expect(blank).to eq("  ")
      expect(stream.index).to eq(0) # Should not move index
    end

    it "handles skip_blank_inline" do
      blank = stream.skip_blank_inline
      expect(blank).to eq("  ")
      expect(stream.index).to eq(2) # Should move index
      expect(stream.current_char).to eq("h")
    end
  end

  describe "character classification" do
    let(:stream) { Foxtail::Parser::Stream.new("a1-_Z9") }

    it "identifies ID start characters" do
      expect(stream.char_id_start?("a")).to be true
      expect(stream.char_id_start?("Z")).to be true
      expect(stream.char_id_start?("1")).to be false
      expect(stream.char_id_start?("-")).to be false
    end

    it "identifies ID characters" do
      stream.next # Move to '1'
      expect(stream.take_id_char).to eq("1")
      expect(stream.take_id_char).to eq("-")
      expect(stream.take_id_char).to eq("_")
      expect(stream.take_id_char).to eq("Z")
      expect(stream.take_id_char).to eq("9")
    end
  end

  describe "number handling" do
    let(:stream) { Foxtail::Parser::Stream.new("123-456") }

    it "identifies number start" do
      expect(stream.number_start?).to be true
      stream.next # Move to '2'
      expect(stream.number_start?).to be true # '2' is still a digit
      3.times { stream.next } # Move to '-'
      expect(stream.number_start?).to be true # '-' followed by digit is a number start
    end

    it "handles negative numbers" do
      stream = Foxtail::Parser::Stream.new("-123")
      expect(stream.number_start?).to be true
    end

    it "rejects non-number starting with dash" do
      stream = Foxtail::Parser::Stream.new("-abc")
      expect(stream.number_start?).to be false
    end

    it "takes digits" do
      expect(stream.take_digit).to eq("1")
      expect(stream.take_digit).to eq("2")
      expect(stream.take_digit).to eq("3")
      expect(stream.take_digit).to be_nil # '-' is not a digit
    end
  end

  describe "EOF handling" do
    let(:stream) { Foxtail::Parser::Stream.new("a") }

    it "handles EOF correctly" do
      expect(stream.current_char).to eq("a")
      stream.next
      expect(stream.current_char).to be_nil # EOF
      expect(stream.current_char).to eq(Foxtail::Parser::Stream::EOF)
    end
  end

  describe "constants" do
    it "defines correct constants" do
      expect(Foxtail::Parser::Stream::EOL).to eq("\n")
      expect(Foxtail::Parser::Stream::EOF).to be_nil
      expect(Foxtail::Parser::Stream::SPECIAL_LINE_START_CHARS).to eq(["}", ".", "[", "*"])
    end
  end

  describe "error handling" do
    let(:stream) { Foxtail::Parser::Stream.new("hello") }

    it "raises ParseError for expect_char mismatch" do
      expect { stream.expect_char("x") }.to raise_error(Foxtail::ParseError, 'Expected token: "x"')
    end

    it "accepts expected character" do
      expect { stream.expect_char("h") }.not_to raise_error
      expect(stream.current_char).to eq("e") # Should advance
    end

    it "raises ParseError for take_id_start with invalid character" do
      stream = Foxtail::Parser::Stream.new("123")
      expect { stream.take_id_start }.to raise_error(Foxtail::ParseError, 'Expected a character from range: "a-zA-Z"')
    end
  end
end
