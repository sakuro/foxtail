# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in foxtail.gemspec
gemspec

group :development, :test do
  gem "docquet", github: "sakuro/docquet" # Unreleased gem
  gem "irb"
  gem "rake"
  gem "redcarpet" # Markdown provider for YARD
  gem "repl_type_completor"
  gem "rexml" # For CLDR XML parsing in rake tasks
  gem "rubocop"
  gem "rubocop-performance"
  gem "rubocop-rake"
  gem "rubocop-rspec"
  gem "yard"
end

group :test do
  gem "rspec"
end
