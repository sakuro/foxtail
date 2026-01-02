# frozen_string_literal: true

source "https://rubygems.org"

gemspec

group :development, :test do
  gem "irb"
  gem "repl_type_completor"

  gem "rake"
end

group :development do
  # RuboCop
  gem "docquet", github: "sakuro/docquet" # An opinionated RuboCop config
  gem "rubocop"
  gem "rubocop-performance"
  gem "rubocop-rake"
  gem "rubocop-rspec"

  # YARD
  gem "gemoji"
  gem "redcarpet"
  gem "yard"

  # Language Server Protocol support
  gem "ruby-lsp"
end

group :test do
  gem "rspec"
  gem "simplecov", require: false
end
