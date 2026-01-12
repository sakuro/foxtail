# frozen_string_literal: true

require "zeitwerk"
require_relative "fantail/version"

# Ruby implementation of Project Fluent localization system
module Fantail
  # Configure Zeitwerk loader for this gem
  loader = Zeitwerk::Loader.for_gem

  # Ignore version.rb since it's required by gemspec before Zeitwerk loads
  loader.ignore(__dir__ + "/fantail/version.rb")

  # Configure inflections for acronyms
  loader.inflector.inflect(
    "ast" => "AST",
    "cli" => "CLI",
    "icu4x_cache" => "ICU4XCache"
  )

  loader.setup
end
