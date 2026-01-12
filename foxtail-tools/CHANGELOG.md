## [Unreleased]

### Added
- **Syntax Tooling**
  - FTL syntax parser with AST support
  - Serializer for round-trip formatting
- **CLI Commands**
  - `foxtail check` - Check FTL files for syntax errors
  - `foxtail dump` - Dump FTL files as AST in JSON format
  - `foxtail ids` - Extract message and term IDs from FTL files
  - `foxtail tidy` - Format FTL files with consistent style

### Compatibility
- fluent.js syntax parser: 97/98 (99.0%)
- Ruby: 3.2+ supported
