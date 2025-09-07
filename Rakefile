# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

require "rubocop/rake_task"

RuboCop::RakeTask.new

require "yard"
YARD::Rake::YardocTask.new

require "rake/clean"
CLEAN.include("docs/api", ".yardoc")

# Load custom tasks
Dir.glob("lib/tasks/*.rake").each {|file| load file }

task default: %i[spec rubocop]
