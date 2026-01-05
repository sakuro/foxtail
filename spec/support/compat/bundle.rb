# frozen_string_literal: true

require_relative "base"

# Compatibility testing support for fluent-bundle
module FluentCompatBundle
  include FluentCompatBase
  extend FluentCompatBase
end

require_relative "bundle/ast_converter"
require_relative "bundle/test_helper"
