# frozen_string_literal: true

require "rake/clean"

CLEAN.include("tmp")

def run_gem_task(gem_dir, task_name)
  puts
  puts "In #{gem_dir}..."
  sh "bundle exec rake -C #{gem_dir} #{task_name}"
end

desc "Run runtime specs"
task "spec:runtime" do
  run_gem_task("foxtail-runtime", "spec")
end

desc "Run tools specs"
task "spec:tools" do
  run_gem_task("foxtail-tools", "spec")
end

desc "Run specs for all gems"
task spec: %i[spec:runtime spec:tools]

desc "Run RuboCop for runtime"
task "rubocop:runtime" do
  run_gem_task("foxtail-runtime", "rubocop")
end

desc "Run RuboCop for tools"
task "rubocop:tools" do
  run_gem_task("foxtail-tools", "rubocop")
end

require "rubocop/rake_task"
desc "Run RuboCop for root tasks"
RuboCop::RakeTask.new(:rubocop) do |t|
  t.patterns = [
    "Rakefile"
  ]
end

desc "Generate YARD docs for runtime"
task "doc:runtime" do
  run_gem_task("foxtail-runtime", "doc")
end

desc "Generate YARD docs for tools"
task "doc:tools" do
  run_gem_task("foxtail-tools", "doc")
end

desc "Generate YARD docs for all gems"
task doc: %i[doc:runtime doc:tools]

desc "Run default task (spec + rubocop)"
task default: %i[spec rubocop]

desc "Clean runtime artifacts"
task "clean:runtime" do
  run_gem_task("foxtail-runtime", "clean")
end

desc "Clean tools artifacts"
task "clean:tools" do
  run_gem_task("foxtail-tools", "clean")
end

desc "Remove runtime build artifacts"
task "clobber:runtime" do
  run_gem_task("foxtail-runtime", "clobber")
end

desc "Remove tools build artifacts"
task "clobber:tools" do
  run_gem_task("foxtail-tools", "clobber")
end

Rake::Task[:rubocop].enhance(%i[rubocop:runtime rubocop:tools])
Rake::Task[:clean].enhance(%i[clean:runtime clean:tools])
Rake::Task[:clobber].enhance(%i[clobber:runtime clobber:tools])
