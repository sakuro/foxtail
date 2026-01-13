# frozen_string_literal: true

require_relative "lib/foxtail/tools/version"

Gem::Specification.new do |spec|
  spec.name = "foxtail-tools"
  spec.version = Foxtail::Tools::VERSION
  spec.authors = ["OZAWA Sakuro"]
  spec.email = ["10973+sakuro@users.noreply.github.com"]

  spec.summary = "Foxtail CLI and syntax tooling for Project Fluent"
  spec.description = <<~DESC
    Tooling components for Foxtail: fluent syntax parser/serializer and CLI utilities.
  DESC
  spec.homepage = "https://github.com/sakuro/foxtail"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "#{spec.homepage}.git"
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/foxtail-tools/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir[
    "lib/**/*.rb",
    "exe/*",
    "CHANGELOG.md",
    "LICENSE.txt",
    "README.md"
  ]
  spec.bindir = "exe"
  spec.executables = ["foxtail"]
  spec.require_paths = ["lib"]

  spec.add_dependency "dry-cli", "~> 1.4"
  spec.add_dependency "dry-inflector", "~> 1.0"
  spec.add_dependency "zeitwerk", "~> 2.7"
end
