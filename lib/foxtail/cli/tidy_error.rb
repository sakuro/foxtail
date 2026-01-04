# frozen_string_literal: true

module Foxtail
  module CLI
    # Raised when tidy command encounters syntax errors without --with-junk
    class TidyError < Error
      attr_reader :files_with_errors

      def initialize(files_with_errors)
        @files_with_errors = files_with_errors
        super("Files contain syntax errors: #{files_with_errors.join(", ")}")
      end
    end
  end
end
