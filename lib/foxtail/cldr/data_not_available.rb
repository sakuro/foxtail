# frozen_string_literal: true

module Foxtail
  module CLDR
    # Exception raised when CLDR data is not available for a locale
    class DataNotAvailable < Error; end
  end
end
