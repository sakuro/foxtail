# frozen_string_literal: true

require "dry/cli"

module Foxtail
  # Command-line interface for Foxtail
  module CLI
    extend Dry::CLI::Registry

    # Base error class for CLI-specific exceptions
    class Error < Foxtail::Error; end

    # Raised when no files are specified for a CLI command
    class NoFilesError < Error
      def initialize = super("No files specified")
    end

    # Raised when lint command finds errors in FTL files
    class LintError < Error
      attr_reader :error_count

      def initialize(error_count)
        @error_count = error_count
        super("Lint found #{error_count} error(s)")
      end
    end

    # Raised when tidy command encounters syntax errors without --with-junk
    class TidyError < Error
      attr_reader :files_with_errors

      def initialize(files_with_errors)
        @files_with_errors = files_with_errors
        super("Files contain syntax errors: #{files_with_errors.join(", ")}")
      end
    end

    # Raised when tidy --check finds files that need formatting
    class TidyCheckError < Error
      attr_reader :files_needing_format

      def initialize(files_needing_format)
        @files_needing_format = files_needing_format
        super("Files need formatting: #{files_needing_format.join(", ")}")
      end
    end

    register "ids", Commands::Ids
    register "lint", Commands::Lint
    register "tidy", Commands::Tidy
  end
end
