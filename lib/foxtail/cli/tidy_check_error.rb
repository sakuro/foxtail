# frozen_string_literal: true

module Foxtail
  module CLI
    # Raised when tidy --check finds files that need formatting
    class TidyCheckError < Error
      attr_reader :files_needing_format

      def initialize(files_needing_format)
        @files_needing_format = files_needing_format
        super("Files need formatting: #{files_needing_format.join(", ")}")
      end
    end
  end
end
