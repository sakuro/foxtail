# frozen_string_literal: true

require_relative "foxtail/version"
require_relative "foxtail/errors"
require_relative "foxtail/stream"
require_relative "foxtail/ast"
require_relative "foxtail/parser"

module Foxtail
  class Error < StandardError; end
end
