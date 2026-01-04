# frozen_string_literal: true

require_relative "ast_comparator"

RSpec::Matchers.define :match_ast do |expected|
  match do |actual|
    expected == actual
  end

  failure_message do |actual|
    comparator = FluentJsCompatibility::AstComparator.new
    differences = comparator.find_differences(expected, actual)

    message = "expected AST to match, but found #{differences.size} difference(s):\n"
    differences.each {|diff| message += "  - #{diff}\n" }
    message
  end
end
