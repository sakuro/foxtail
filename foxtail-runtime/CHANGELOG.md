## [Unreleased]

### Added
- **Core System**
  - Ruby implementation of Project Fluent localization system
  - Runtime message formatting with Bundle system
  - Pattern selection with pluralization support
  - `Sequence` class for language fallback chains
  - Bidi isolation support (`use_isolating` option)
- **Formatting Features**
  - `icu4x`-based number and date formatting
  - Built-in functions: NUMBER() and DATETIME()
  - Implicit NUMBER/DATETIME function calling for numeric and time variables
- **Examples**
  - Executable usage demonstrations in `examples/`
### Compatibility
- fluent.js bundle parser: 62/62 (100%)
- Ruby: 3.2+ supported
