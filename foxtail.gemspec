# frozen_string_literal: true

require_relative "lib/foxtail/version"

Gem::Specification.new do |spec|
  spec.name = "foxtail"
  spec.version = Foxtail::VERSION
  spec.authors = ["OZAWA Sakuro"]
  spec.email = ["10973+sakuro@users.noreply.github.com"]

  spec.summary = "Ruby implementation of Project Fluent localization system"
  spec.description = <<~DESC
    A Ruby implementation of Project Fluent - a modern localization system designed to improve how software is translated.#{" "}
    Provides high fluent.js compatibility with FTL syntax parsing, runtime message formatting, and ICU4X integration.
  DESC
  spec.homepage = "https://github.com/sakuro/foxtail"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "#{spec.homepage}.git"
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir[
    "lib/**/*.rb",
    "CHANGELOG.md",
    "LICENSE.txt",
    "README.md"
  ]
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) {|f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Dependencies
  spec.add_dependency "icu4x", "~> 0.6"
  spec.add_dependency "zeitwerk", "~> 2.6"
end
