# frozen_string_literal: true

# AST node classes - require in dependency order

# Base classes first
require_relative "ast/base_node"
require_relative "ast/syntax_node"

# Core AST nodes
require_relative "ast/span"
require_relative "ast/resource"
require_relative "ast/message"
require_relative "ast/term"
require_relative "ast/pattern"
require_relative "ast/text_element"
require_relative "ast/placeable"
require_relative "ast/identifier"
require_relative "ast/attribute"

# Literal classes
require_relative "ast/base_literal"
require_relative "ast/string_literal"
require_relative "ast/number_literal"

# Reference classes
require_relative "ast/variable_reference"
require_relative "ast/message_reference"
require_relative "ast/term_reference"
require_relative "ast/function_reference"

# Expression classes
require_relative "ast/select_expression"
require_relative "ast/variant"
require_relative "ast/named_argument"
require_relative "ast/call_arguments"

# Comment classes
require_relative "ast/base_comment"
require_relative "ast/comment"
require_relative "ast/group_comment"
require_relative "ast/resource_comment"

# Error handling classes
require_relative "ast/junk"
require_relative "ast/annotation"