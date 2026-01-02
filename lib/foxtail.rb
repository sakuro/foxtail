# frozen_string_literal: true

require "pathname"
require "zeitwerk"
require_relative "foxtail/version"

# Ruby implementation of Project Fluent localization system
module Foxtail
  # Root directory of the gem
  ROOT = Pathname(__dir__).parent.expand_path.freeze
  public_constant :ROOT

  # Configure Zeitwerk loader for this gem
  loader = Zeitwerk::Loader.for_gem

  # Ignore version.rb since it's required by gemspec before Zeitwerk loads
  loader.ignore(__dir__ + "/foxtail/version.rb")

  # Configure inflections for acronyms
  loader.inflector.inflect(
    "ast" => "AST",
    "ast_converter" => "ASTConverter"
  )

  loader.setup
end
