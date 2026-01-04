# frozen_string_literal: true

require "dry/cli"

module Foxtail
  # Command-line interface for Foxtail
  module CLI
    extend Dry::CLI::Registry

    register "lint", Commands::Lint
  end
end
