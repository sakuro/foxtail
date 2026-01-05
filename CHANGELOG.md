## [Unreleased]

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
- **CLI Commands**
  - `foxtail lint` - Check FTL files for syntax errors
  - `foxtail tidy` - Format FTL files with consistent style
  - `foxtail ids` - Extract message and term IDs from FTL files
- **Documentation**
  - Examples directory with executable usage demonstrations

### Compatibility
- fluent.js: 159/160 test fixtures passing (99.4%)
  - Syntax parser: 97/98 (99.0%)
  - Bundle parser: 62/62 (100%)
- Ruby: 3.2+ supported
