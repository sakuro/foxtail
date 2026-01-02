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
    Provides high fluent.js compatibility with FTL syntax parsing, runtime message formatting, and Unicode CLDR integration.
  DESC
  spec.homepage = "https://github.com/sakuro/foxtail"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.9"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "#{spec.homepage}.git"
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) {|ls|
    ls.each_line("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  }
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) {|f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Dependencies
  spec.add_dependency "bigdecimal", "~> 3.0"
  spec.add_dependency "dry-inflector", "~> 1.0"
  spec.add_dependency "dry-logger", "~> 1.0"
  spec.add_dependency "icu4x", "~> 0.6"
  spec.add_dependency "icu4x-data-recommended", "~> 0.6"
  spec.add_dependency "locale", "~> 2.1"
  spec.add_dependency "tzinfo", "~> 2.0"
  spec.add_dependency "zeitwerk", "~> 2.6"
end
