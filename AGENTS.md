# Foxtail - Code Instructions for AI Coding Agents

## What is Foxtail?

A Ruby implementation of [Project Fluent](https://projectfluent.org/) - a modern localization system designed to improve how software is translated.

## Documentation Map

| Purpose | Document |
|---------|----------|
| Project overview & usage | [README.md](README.md) |
| Architecture & design | [doc/architecture.md](doc/architecture.md) |
| FTL syntax support | [doc/ftl-syntax.md](doc/ftl-syntax.md) |
| Bundle system details | [doc/bundle-system.md](doc/bundle-system.md) |
| Custom functions | [doc/custom-functions.md](doc/custom-functions.md) |
| Language fallback | [doc/sequence.md](doc/sequence.md) |
| Language negotiation | [doc/language-negotiation.md](doc/language-negotiation.md) |
| `icu4x` integration | [doc/icu4x-integration.md](doc/icu4x-integration.md) |
| CLI reference | [doc/cli.md](doc/cli.md) |
| Testing strategy | [doc/testing.md](doc/testing.md) |

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

## Configuration

- **Ruby version**: >= 3.2
- **RuboCop style**: Double quotes for strings
- **Release**: Automated via CI workflow

See [doc/architecture.md](doc/architecture.md) for detailed architecture information.
