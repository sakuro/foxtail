# frozen_string_literal: true

require "icu4x"
require "zeitwerk"
require_relative "foxtail/runtime/version"

# Ruby implementation of Project Fluent localization system
module Foxtail
  # Configure Zeitwerk loader for this gem
  loader = Zeitwerk::Loader.new
  loader.push_dir(__dir__ + "/foxtail", namespace: Foxtail)

  # Ignore version.rb since it's required by gemspec before Zeitwerk loads
  loader.ignore(__dir__ + "/foxtail/runtime/version.rb")
  # Ignore gem entrypoint file (no constant defined)
  loader.ignore(__dir__ + "/foxtail.rb")
  loader.ignore(__dir__ + "/foxtail-runtime.rb")

  # Configure inflections for acronyms
  loader.inflector.inflect(
    "ast" => "AST",
    "datetime" => "DateTime",
    "icu4x_cache" => "ICU4XCache"
  )

  loader.setup
end
