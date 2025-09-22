# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Development Setup
- **Setup dependencies**: `bin/setup` - Installs all gem dependencies

### Testing
- **Run tests**: `rake spec` or `bundle exec rspec`
- **Run a single test file**: `bundle exec rspec spec/path/to/file_spec.rb`
- **Run tests with specific example**: `bundle exec rspec spec/path/to/file_spec.rb:line_number`

#### Compatibility Testing

##### Fluent.js Compatibility
- **Compatibility report**: `rake compatibility:fluentjs` - Comprehensive Fluent.js compatibility report (97/98 passing)
- **RSpec directly**: `bundle exec rspec spec/fluent_js_compatibility_spec.rb`

##### Node.js Intl.NumberFormat Compatibility
- **Compatibility report**: `rake compatibility:node_intl` - Node.js Intl.NumberFormat compatibility report
- Compares Foxtail number formatting with Node.js Intl.NumberFormat behavior
- Tests decimal, currency, percent, and scientific notation formatting across multiple locales

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

### Documentation
- **Generate YARD docs**: `rake yard` - Generate API documentation with YARD
- **View documentation**: Open `docs/api/index.html` in browser after generation

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

## Additional Agent Guidelines

This project includes specialized documentation for AI agents to ensure consistent, high-quality contributions. All agents should read and follow these guidelines:

### Agent Documentation Directory
- **[docs/agents/rubocop.md](docs/agents/rubocop.md)** - RuboCop fix workflows and style enforcement procedures
- **[docs/agents/languages.md](docs/agents/languages.md)** - Language usage conventions for multilingual projects  
- **[docs/agents/git-pr.md](docs/agents/git-pr.md)** - Git commit and pull request guidelines with proper formatting

### Required Reading Instructions
AI agents MUST read the following documentation files before working on this project:
1. Read `docs/agents/rubocop.md` for code style and linting procedures
2. Read `docs/agents/languages.md` for proper language usage in different contexts
3. Read `docs/agents/git-pr.md` for Git workflow and commit message formatting

These documents provide essential context for maintaining code quality, following project conventions, and ensuring professional collaboration standards.
- まだ後悔していないユーザー一人のプロダクトなので、互換性や移行パスは考慮しなくてよい。