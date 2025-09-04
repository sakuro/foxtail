# frozen_string_literal: true

module Foxtail
  # Ruby equivalent of fluent.js ParseError
  class ParseError < StandardError
    attr_reader :code, :args

    def initialize(code, *args)
      @code = code
      @args = args
      super(error_message(code, args))
    end

    private

    def error_message(code, args)
      case code
      when "E0001"
        "Generic error"
      when "E0002"
        "Expected an entry start"
      when "E0003"
        token = args[0]
        "Expected token: \"#{token}\""
      when "E0004"
        range = args[0]
        "Expected a character from range: \"#{range}\""
      when "E0005"
        range = args[0]
        "Expected a number"
      when "E0006"
        "Expected a variant key"
      when "E0007"
        "Expected a keyword"
      when "E0008"
        "Expected a closing brace"
      when "E0009"
        "Expected a closing bracket"
      when "E0010"
        "Expected a closing parenthesis"
      when "E0011"
        "Expected digits after the decimal point"
      when "E0012"
        "Expected a function name"
      when "E0013"
        "Expected a literal"
      when "E0014"
        "Expected a message reference"
      when "E0015"
        "Expected a term reference"
      when "E0016"
        "Expected a variable reference"
      when "E0017"
        "Expected a select expression"
      when "E0018"
        "Expected a variant list"
      when "E0019"
        "Expected an identifier"
      when "E0020"
        "Expected a string literal"
      when "E0021"
        "Expected a number literal"
      when "E0022"
        "Expected a function call"
      when "E0023"
        "Expected an option list"
      when "E0024"
        "Expected a keyword argument"
      when "E0025"
        "Expected a function argument"
      when "E0026"
        "Expected a closing quote"
      when "E0027"
        "Expected valid escape sequence"
      else
        "Unknown error: #{code}"
      end
    end
  end
end