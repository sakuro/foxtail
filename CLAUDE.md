# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Development Setup
- **Setup dependencies**: `bin/setup` - Installs all gem dependencies

### Testing
- **Run tests**: `rake spec` or `bundle exec rspec`
- **Run a single test file**: `bundle exec rspec spec/path/to/file_spec.rb`
- **Run tests with specific example**: `bundle exec rspec spec/path/to/file_spec.rb:line_number`

### Linting & Code Style
- **Run RuboCop linter**: `rake rubocop` or `bundle exec rubocop`
- **Auto-fix RuboCop issues**: `bundle exec rubocop -a`
- **Run all checks (tests + linting)**: `rake` - This is the default task

### Building & Installation
- **Build the gem**: `bundle exec rake build`
- **Install locally**: `bundle exec rake install`
- **Release to RubyGems**: `bundle exec rake release` (requires proper credentials)

### Development Console
- **Interactive console**: `bin/console` - Opens an IRB session with the gem loaded

## Architecture

This is a Ruby gem project with a standard structure:

### Core Structure
- **lib/foxtail.rb**: Main entry point that requires the module and version
- **lib/foxtail/**: Directory for the gem's Ruby implementation files
- **lib/foxtail/version.rb**: Defines the gem version (currently 0.1.0)

### Testing
- **spec/**: RSpec test directory
- **spec/spec_helper.rb**: RSpec configuration with persistence and expect syntax
- Tests use RSpec with monkey patching disabled

### Configuration
- **Ruby version**: Requires Ruby >= 3.4.5 (specified in gemspec)
- **RuboCop style**: Enforces double quotes for strings (see .rubocop.yml)
- **Default task**: Runs both tests and RuboCop when executing `rake` without arguments