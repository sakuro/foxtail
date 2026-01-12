# frozen_string_literal: true

require "rake/clean"
CLEAN.include("coverage", ".rspec_status", ".yardoc")
CLOBBER.include("doc/api", "pkg")

require "rspec/core/rake_task"
RSpec::Core::RakeTask.new("spec:runtime") do |t|
  t.pattern = "foxtail-runtime/spec/**/*_spec.rb"
  t.rspec_opts = ["--require", "foxtail-runtime/spec/spec_helper"]
  t.ruby_opts = ["-Ifoxtail-runtime", "-I."]
end

RSpec::Core::RakeTask.new("spec:tools") do |t|
  t.pattern = "foxtail-tools/spec/**/*_spec.rb"
  t.rspec_opts = ["--require", "foxtail-tools/spec/spec_helper"]
  t.ruby_opts = ["-Ifoxtail-tools", "-I."]
end

task spec: %i[spec:runtime spec:tools]

require "rubocop/rake_task"
RuboCop::RakeTask.new("rubocop:runtime") do |t|
  t.patterns = [
    "foxtail-runtime/lib/**/*.rb",
    "foxtail-runtime/spec/**/*.rb",
    "foxtail-runtime/*.gemspec"
  ]
end

RuboCop::RakeTask.new("rubocop:tools") do |t|
  t.patterns = [
    "foxtail-tools/exe/*",
    "foxtail-tools/lib/**/*.rb",
    "foxtail-tools/spec/**/*.rb",
    "foxtail-tools/*.gemspec"
  ]
end

task rubocop: %i[rubocop:runtime rubocop:tools]

require "yard"
YARD::Rake::YardocTask.new(:doc) do |t|
  t.files = ["foxtail-runtime/lib/**/*.rb", "foxtail-tools/lib/**/*.rb"]
end

task default: %i[spec rubocop]
