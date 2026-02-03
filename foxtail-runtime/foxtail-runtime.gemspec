# frozen_string_literal: true

require_relative "lib/foxtail/runtime/version"

Gem::Specification.new do |spec|
  spec.name = "foxtail-runtime"
  spec.version = Foxtail::Runtime::VERSION
  spec.authors = ["OZAWA Sakuro"]
  spec.email = ["10973+sakuro@users.noreply.github.com"]

  spec.summary = "Foxtail runtime for Project Fluent localization"
  spec.description = <<~DESC
    Runtime components for Foxtail: bundle parsing, message formatting, and ICU4X integration.
  DESC
  spec.homepage = "https://github.com/sakuro/foxtail"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "#{spec.homepage}.git"
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/foxtail-runtime/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir[
    "lib/**/*.rb",
    "CHANGELOG.md",
    "LICENSE.txt",
    "README.md"
  ]
  spec.require_paths = ["lib"]

  spec.add_dependency "bigdecimal", ">= 3.1"
  spec.add_dependency "dry-core", "~> 1.1"
  spec.add_dependency "icu4x", "~> 0.9"
  spec.add_dependency "zeitwerk", "~> 2.7"
end
