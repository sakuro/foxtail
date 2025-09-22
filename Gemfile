# frozen_string_literal: true

source "https://rubygems.org"

gemspec

group :development, :test do
  gem "irb"
  gem "repl_type_completor"

  gem "rake"
end

group :development do
  # Function backends (we use JavaScript backend in development and test for now)
  gem "execjs", "~> 2.7"

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

  gem "rexml" # For CLDR XML parsing in rake tasks

  # Language Server Protocol support
  gem "ruby-lsp"
end

group :test do
  gem "rspec"
  gem "simplecov", require: false
end
