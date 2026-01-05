# FTL Syntax Support

## Overview

FTL (Fluent Translation List) is the file format used by [Project Fluent](https://projectfluent.org/). Foxtail implements a parser that is compatible with the [FTL Syntax Specification](https://github.com/projectfluent/fluent/blob/master/spec/fluent.ebnf). A local copy is available at `doc/fluent.ebnf`.

**Compatibility**: 97/98 fluent-syntax test fixtures passing (99.0%)

## Syntax Elements

### Messages

Messages are the basic units of translation. A message has an identifier and a pattern (value).

```ftl
# Simple message
hello = Hello, World!

# Message with placeable
greeting = Hello, {$name}!

# Message with attributes
login-button = Log In
    .aria-label = Click to log in
    .title = Authentication
```

### Terms

Terms are reusable values that start with `-`. They cannot be used as selectors directly.

```ftl
# Term definition
-brand-name = Foxtail

# Term with variants
-adjective = { $case ->
    [uppercase] Beautiful
   *[lowercase] beautiful
}

# Using terms
about = About {-brand-name}
tagline = A {-adjective(case: "lowercase")} localization system
```

### Attributes

Both messages and terms can have attributes, accessed with `.`:

```ftl
login = Log In
    .placeholder = Enter username
    .aria-label = Login field

# Referencing attribute
help = {login.aria-label}
```

## Patterns

Patterns are the values of messages, terms, and attributes.

### Simple Patterns

```ftl
simple = Just text
```

### Multiline Patterns

Continuation lines must be indented:

```ftl
multiline =
    This is a
    multiline message
    that spans several lines.
```

### Placeables

Placeables are expressions wrapped in `{ }`:

```ftl
# Variable reference
welcome = Welcome, {$user}!

# Message reference
see-also = See also: {other-message}

# Term reference
powered-by = Powered by {-brand-name}

# Function call
count = {NUMBER($num, style: "decimal")}

# Literal
quoted = This is {"literal text"}
```

## Expressions

### Variable References

Variables are external values passed at runtime, prefixed with `$`:

```ftl
hello = Hello, {$name}!
```

### Message References

Reference other messages by identifier:

```ftl
brand = Foxtail
tagline = {brand} is great!
```

### Term References

Reference terms with `-` prefix:

```ftl
-brand = Foxtail
about = About {-brand}

# With arguments
-term = { $case ->
   *[nom] Term
    [acc] the Term
}
using = Using {-term(case: "acc")}
```

### Function Calls

Built-in functions for formatting:

```ftl
# NUMBER function
price = {NUMBER($amount, style: "currency", currency: "USD")}
percent = {NUMBER($ratio, style: "percent")}

# DATETIME function
date = {DATETIME($timestamp, dateStyle: "long")}
```

### Literals

#### String Literals

```ftl
quoted = {"Quoted text"}
empty = {""}
```

#### Number Literals

```ftl
count = { 42 }
negative = { -3.14 }
```

## Select Expressions

Pattern selection based on runtime values:

### Basic Selection

```ftl
emails = { $count ->
    [0] No emails
    [one] One email
   *[other] {$count} emails
}
```

- `*` marks the default variant (required)
- Variant keys can be identifiers or numbers

### Selector Types

Valid selectors:
- Variables: `{$var -> ...}`
- Function calls: `{FUNCTION($arg) -> ...}`
- Term attributes: `{-term.attr -> ...}`

Invalid selectors (will produce errors):
- Term values: `{-term -> ...}`
- Message references: `{message -> ...}`
- Nested expressions

### Plural Categories

Used with the NUMBER function for pluralization:

```ftl
items = { NUMBER($count) ->
    [zero] No items
    [one] One item
    [two] Two items
    [few] A few items
    [many] Many items
   *[other] {$count} items
}
```

Categories depend on locale (handled by `icu4x`).

## Comments

Three levels of comments:

```ftl
# Comment (attached to following message)
message = Value

## Group Comment (section header)

### Resource Comment (file-level documentation)
```

Comments must have a space after `#`:

```ftl
# Valid comment
#Invalid (parsed as junk)
```

## Escape Sequences

### In Patterns (Text)

Backslash is literal in patterns:

```ftl
path = C:\Users\name
```

To include literal `{` or `}`:

```ftl
braces = Use {"{"} and {"}"} for placeables
```

### In String Literals

String literals support escape sequences:

| Escape | Result |
|--------|--------|
| `\"` | Double quote |
| `\\` | Backslash |
| `\u0041` | Unicode (4 hex digits) → `A` |
| `\U01F602` | Unicode (6 hex digits) → 😂 |

```ftl
escaped = {"Quote: \" Backslash: \\"}
unicode = {"\u0048\u0065\u006C\u006C\u006F"}  # Hello
emoji = {"\U01F600"}  # 😀
```

## Error Handling

The syntax parser uses error recovery. Invalid syntax is wrapped in `Junk` entries:

```ftl
valid = This is valid

# This line has a syntax error
= missing identifier

another = This is also valid
```

The syntax parser continues after errors, collecting valid entries.

### Common Errors

| Error | Example |
|-------|---------|
| Missing value | `key =` (empty) |
| Missing `=` | `key` (no equals) |
| Invalid identifier | `0key`, `key?` |
| Missing default variant | `{ $x -> [a] A }` |
| Invalid selector | `{ {nested} -> ... }` |

## Parser AST

The syntax parser produces an AST with 28 node types:

| Category | Node Types |
|----------|------------|
| Entries | `Resource`, `Message`, `Term`, `Junk` |
| Comments | `Comment`, `GroupComment`, `ResourceComment` |
| Patterns | `Pattern`, `TextElement`, `Placeable` |
| Expressions | `SelectExpression`, `VariableReference`, `MessageReference`, `TermReference`, `FunctionReference` |
| Literals | `StringLiteral`, `NumberLiteral` |
| Other | `Identifier`, `Attribute`, `Variant`, `CallArguments`, `NamedArgument` |
| Metadata | `Span`, `Annotation` |

### Span Tracking

The syntax parser optionally tracks source positions:

```ruby
parser = Foxtail::Syntax::Parser.new(with_spans: true)
ast = parser.parse(source)
# Each node has a span with start/end positions
```

## Compatibility Notes

### Known Mismatches

One fixture (`leading_dots`) is marked as pending. This test also fails in fluent.js itself.

### Recommended Practices

1. Always provide a default variant in select expressions
2. Use terms for reusable content
3. Avoid deeply nested placeables
4. Comment your messages for translators
