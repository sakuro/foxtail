# Fluent.js Compatibility Testing

This directory contains the fluent.js compatibility testing system for Foxtail. It compares the parsing output of Foxtail's Ruby parser against the reference fluent.js parser to ensure compatibility.

## Architecture

The compatibility testing system consists of three main components:

### `CompatibilityTester` (`compatibility_tester.rb`)

Main testing engine that:
- Loads fixture pairs (.ftl/.json) from fluent.js test suites
- Parses FTL source using Foxtail's parser
- Compares actual AST output against expected fluent.js AST
- Returns structured test results with status classification

**Key Methods:**
- `test_structure_fixtures()` - Tests with span information (62 fixtures)
- `test_reference_fixtures()` - Tests without spans + junk processing (36 fixtures)  
- `test_all_fixtures()` - Runs both test suites (98 total fixtures)

### `AstComparator` (`ast_comparator.rb`)

AST comparison engine that:
- Performs deep comparison between expected and actual AST structures
- Classifies differences as perfect match, partial match, or content difference
- Handles span-related differences separately for structural comparison
- Provides detailed difference reporting for debugging

**Status Classification:**
- `:perfect_match` - Exact match with fluent.js output
- `:partial_match` - Structural match with minor differences (e.g., spans)
- `:content_difference` - Significant parsing differences
- `:parsing_failure` - Parser error or exception
- `:known_incompatibility` - Intentional difference from fluent.js

### `CompatibilityReporter` (`compatibility_reporter.rb`)

Report generation that:
- Calculates statistics from test results
- Generates console summary (simple one-line format)
- Generates detailed Markdown reports with tables and fixture lists
- Separates perfect matches by category (structure/reference)

## Usage

### Running Tests

```bash
# Generate compatibility report
bundle exec rake compatibility:report

# Output:
# Fluent.js Compatibility: 97/98 perfect matches (99.0%), 97/98 functional (99.0%)
# 📄 Detailed report saved to compatibility_report.md
```

### Integration

The system is integrated into:
- **CI/CD**: GitHub Actions runs compatibility tests on Ruby 3.4.5
- **Artifacts**: Detailed reports uploaded as workflow artifacts
- **PR Comments**: Summary statistics posted to pull requests

## Fixture Sources

Tests use official fluent.js fixtures from the `fluent.js/fluent-syntax/test/` directory:

- **Structure Fixtures** (`fixtures_structure/`): 62 tests with span information
- **Reference Fixtures** (`fixtures_reference/`): 36 tests for content validation

Each fixture pair consists of:
- `.ftl` - Fluent source code
- `.json` - Expected AST output from fluent.js parser

## Current Status

- **Perfect Compatibility**: 97/98 fixtures (99.0%)
- **Functional Compatibility**: 97/98 fixtures (99.0%)
- **Known Incompatibilities**: 1 fixture (`leading_dots` - intentional difference)

The high compatibility rate demonstrates Foxtail's parser faithfully implements the fluent.js specification while maintaining Ruby-native patterns and conventions.

## Implementation Details

### Span Handling
- Structure tests include position/span information
- Reference tests focus on content without spans
- Span differences are classified separately to avoid false negatives

### Junk Processing
- Reference fixtures process `Junk` entries with empty annotations
- Maintains compatibility with fluent.js error handling patterns

### Error Classification
- Parser failures are distinguished from content differences
- Provides actionable feedback for debugging parsing issues