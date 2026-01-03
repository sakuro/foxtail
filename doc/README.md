# Documentation

## Grammar Definition

### fluent.ebnf

The official EBNF grammar specification for Fluent Translation List (FTL) format.

**Source**: https://github.com/projectfluent/fluent/blob/master/spec/fluent.ebnf

This file defines the formal syntax rules for:
- **Resource structure** - Top-level organization of FTL files
- **Messages** - Translation keys with patterns
- **Terms** - Reusable translation elements (prefixed with `-`)
- **Attributes** - Properties attached to messages/terms
- **Patterns** - Text with placeholders and expressions
- **Expressions** - Variables, selectors, function calls
- **Comments** - Single (#), group (##), and resource (###) level

The grammar serves as the authoritative reference for implementing the FTL parser in Ruby.
