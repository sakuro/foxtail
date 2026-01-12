## [Unreleased]

## [0.5.0] - 2026-01-12

### Added
- **Core System**
  - Ruby implementation of Project Fluent localization system
  - FTL syntax parser with AST support
  - Runtime message formatting with Bundle system
  - Pattern selection with pluralization support
  - `Sequence` class for language fallback chains
  - Bidi isolation support (`use_isolating` option)
- **Formatting Features**
  - `icu4x`-based number and date formatting
  - Built-in functions: NUMBER() and DATETIME()
  - Implicit NUMBER/DATETIME function calling for numeric and time variables
- **CLI Commands**
  - `foxtail check` - Check FTL files for syntax errors
  - `foxtail dump` - Dump FTL files as AST in JSON format
  - `foxtail ids` - Extract message and term IDs from FTL files
  - `foxtail tidy` - Format FTL files with consistent style
- **Documentation**
  - Examples directory with executable usage demonstrations

### Compatibility
- fluent.js: 159/160 test fixtures passing (99.4%)
  - Syntax parser: 97/98 (99.0%)
  - Bundle parser: 62/62 (100%)
- Ruby: 3.2+ supported
