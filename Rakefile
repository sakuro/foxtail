# frozen_string_literal: true

require "bundler/gem_tasks"

require "rake/clean"
CLEAN.include("coverage", ".rspec_status", ".yardoc")
CLOBBER.include("docs/api", "pkg")

require "rspec/core/rake_task"
RSpec::Core::RakeTask.new(:spec)

require "rubocop/rake_task"
RuboCop::RakeTask.new

require "gemoji"
require "yard"
YARD::Rake::YardocTask.new(:doc)
Rake::Task[:doc].enhance do
  # Convert GitHub emoji shortcodes to actual emojis in generated HTML
  Dir["docs/api/**/*.html"].each do |file|
    content = File.read(file)

    # Replace :emoji_name: patterns with actual unicode emojis
    content.gsub!(/:([a-z0-9+\-_]+):/) do |match|
      alias_name = $1
      emoji = Emoji.find_by_alias(alias_name)
      emoji ? emoji.raw : match # Keep original if emoji not found
    end

    File.write(file, content)
  end
end

# Load custom tasks
Dir.glob("lib/tasks/*.rake").each {|file| load file }

# Ensure CLDR data is available before building the gem
desc "Build foxtail-#{Foxtail::VERSION}.gem with CLDR data"
task build: "cldr:extract:all"

task default: %i[spec rubocop]
