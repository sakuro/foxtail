# frozen_string_literal: true

module Foxtail
  module CLI
    # Raised when lint command finds errors in FTL files
    class LintError < Error
      attr_reader :error_count

      def initialize(error_count)
        @error_count = error_count
        super("Lint found #{error_count} error(s)")
      end
    end
  end
end
