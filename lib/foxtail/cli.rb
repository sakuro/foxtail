# frozen_string_literal: true

require "dry/cli"

module Foxtail
  # Command-line interface for Foxtail
  module CLI
    extend Dry::CLI::Registry

    register "ids", Commands::Ids
    register "lint", Commands::Lint
    register "tidy", Commands::Tidy
  end
end
