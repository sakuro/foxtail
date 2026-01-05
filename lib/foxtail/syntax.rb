# frozen_string_literal: true

module Foxtail
  # Syntax module provides full FTL parsing with complete AST representation.
  # This is the fluent-syntax equivalent, suitable for tools like linters,
  # formatters, and editors that need position information and comments.
  #
  # For runtime message formatting, use {Foxtail::Bundle} instead which uses
  # a lightweight parser optimized for execution.
  module Syntax
  end
end
