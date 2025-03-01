# Test Fixtures

This directory contains test fixtures for the Foxtail parser.

## Origin

The test fixtures in this directory are derived from the [fluent-js](https://github.com/projectfluent/fluent.js) project, specifically from the `fluent-syntax` package's test fixtures.

### structure/

Files in the `structure/` directory are from `fluent-js/fluent-syntax/test/fixtures_structure/`. These files test the structural aspects of the FTL format, such as:

- Simple messages
- Attributes
- Select expressions
- Messages without values
- Terms
- Nested placeables
- Escape sequences
- Resource comments
- Multiline patterns
- Variant keys
- Call expression errors
- Function call arguments
- Junk (error handling)
- Whitespace handling

### reference/

Files in the `reference/` directory are from `fluent-js/fluent-syntax/test/fixtures_reference/`. These files test reference expressions and more complex FTL features, such as:

- Variable references
- Call expressions
- Reference expressions
- Select expressions
- Term parameters
- Variables

## License

The original test fixtures are part of the fluent-js project, which is licensed under the Apache License 2.0.
