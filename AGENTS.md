# Foxtail - Code Instructions for AI Coding Agents

## What is Foxtail?

A Ruby implementation of [Project Fluent](https://projectfluent.org/) - a modern localization system designed to improve how software is translated.

## Core Principles

### Language Policy

- **Code & documentation**: English
- **Commit messages**: English with `:emoji:` notation (e.g., `:sparkles:`, `:bug:`)
- **Chat**: Use the user's language

### Terminology

- **ICU4X**: Unicode org's internationalization project
- **`icu4x`**: Ruby gem providing ICU4X bindings

### Skills

- Explore available skills and use them proactively when applicable

## Development Setup

```bash
bin/setup  # Installs dependencies, configures icu4x, initializes fluent.js submodule
```

- **`icu4x` configuration**: `ICU4X_DATA_PATH` environment variable (auto-configured in `.env`)
- **fluent.js submodule**: `fluent.js/` - Reference implementation for compatibility testing

## Development Commands

```bash
bundle exec rake            # Run all checks (spec + rubocop)
bundle exec rspec           # Run tests
bundle exec rubocop -a      # Auto-fix style
bin/console                 # Interactive console
bundle exec rake doc        # Generate YARD documentation
```

## Architecture

### Core Structure

- **lib/foxtail.rb**: Main entry point
- **lib/foxtail/**: Ruby implementation files
- **spec/**: RSpec test directory

### Configuration

- **Ruby version**: >= 3.2
- **RuboCop style**: Double quotes for strings
- **Release**: Automated via CI workflow
