# frozen_string_literal: true

require "dry/logger"

module Foxtail
  # CLDR (Common Locale Data Repository) integration
  # Provides ICU-compliant plural rules and datetime formatting data
  module CLDR
    # Logger instance for CLDR-related operations
    def self.logger
      @logger ||= Dry.Logger(:cldr)
    end
  end
end
