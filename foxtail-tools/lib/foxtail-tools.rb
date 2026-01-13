# frozen_string_literal: true

require "zeitwerk"
require_relative "foxtail/tools/version"

# Tooling entrypoint for Foxtail (syntax + CLI)
module Foxtail
  loader = Zeitwerk::Loader.new
  loader.push_dir(__dir__ + "/foxtail", namespace: Foxtail)

  # Ignore version.rb since it's required by gemspec before Zeitwerk loads
  loader.ignore(__dir__ + "/foxtail/tools/version.rb")
  # Ignore gem entrypoint file (no constant defined)
  loader.ignore(__dir__ + "/foxtail-tools.rb")

  loader.inflector.inflect(
    "ast" => "AST",
    "cli" => "CLI"
  )

  loader.setup
end
