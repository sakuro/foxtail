# frozen_string_literal: true

require_relative "base"

# Compatibility testing support for fluent-syntax
module FluentCompatSyntax
  include FluentCompatBase
  extend FluentCompatBase
end

require_relative "syntax/ast_comparator"
require_relative "syntax/matchers"
require_relative "syntax/test_helper"
