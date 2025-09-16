# frozen_string_literal: true

require "dry/logger"

module Foxtail
  # CLDR (Common Locale Data Repository) integration
  # Provides ICU-compliant plural rules and datetime formatting data
  module CLDR
    # CLDR source data version used by this gem
    SOURCE_VERSION = "46"
    public_constant :SOURCE_VERSION

    # Logger instance for CLDR-related operations
    def self.logger
      @logger ||= Dry.Logger(:cldr)
    end

    # Set logger instance for CLDR-related operations
    def self.logger=(new_logger)
      @logger = new_logger
    end
  end
end
