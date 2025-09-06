# frozen_string_literal: true

require_relative "foxtail/bundle"
require_relative "foxtail/cldr"
require_relative "foxtail/errors"
require_relative "foxtail/functions"
require_relative "foxtail/parser"
require_relative "foxtail/parser/ast"
require_relative "foxtail/resource"
require_relative "foxtail/stream"
require_relative "foxtail/version"

module Foxtail
  class Error < StandardError; end
end
