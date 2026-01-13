# Foxtail Tools Architecture

## Overview

`foxtail-tools` provides authoring and validation tooling on top of the full syntax AST. It depends on `foxtail-runtime` for shared runtime types and exposes the `Foxtail::Syntax` API and CLI.

## Syntax Parser (`Syntax::Parser`) → `Syntax::Parser::AST`

- **Purpose**: Full-featured parser for tooling (linting, editing, serialization)
- **Output**: Complete AST with source positions (spans), comments, and detailed structure
- **AST**: Class-based nodes inheriting from `BaseNode`, comments and Junk preserved
- **Use Cases**: CLI tools (`check`, `dump`, `ids`, `tidy`), syntax analysis

## Core Components

### Syntax Layer

| Component | File | Responsibility |
|-----------|------|----------------|
| `Syntax::Parser` | `lib/foxtail/syntax/parser.rb` | FTL source → Full AST |
| `Syntax::Parser::Stream` | `lib/foxtail/syntax/parser/stream.rb` | Character-by-character reading |
| `Syntax::Parser::AST::*` | `lib/foxtail/syntax/parser/ast/` | AST node classes |
| `Syntax::Serializer` | `lib/foxtail/syntax/serializer.rb` | AST → FTL source |

The syntax parser reads FTL source and produces a detailed AST with source position tracking (spans). It preserves comments and junk for tooling use cases.

## Tooling Data Flow

```ruby
source = "hello = Hello"
parser = Foxtail::Syntax::Parser.new
ast = parser.parse(source)
# => Syntax::Parser::AST::Resource

serializer = Foxtail::Syntax::Serializer.new
output = serializer.serialize(ast)
# => "hello = Hello\n"
```

## Error Handling

- **Syntax parser errors**: Wrapped in `Junk` entries with `Annotation`
- **Formatting with errors**: `Syntax::Serializer` can include or omit Junk entries

## File Structure

```
lib/foxtail/
├── syntax/
│   ├── parser.rb              # Syntax::Parser (full AST)
│   ├── serializer.rb          # Syntax::Serializer
│   └── parser/
│       ├── stream.rb          # Syntax::Parser::Stream
│       └── ast/               # Syntax::Parser::AST
```

## fluent.js Correspondence

| Foxtail | fluent.js | Purpose |
|---------|-----------|---------|
| `Foxtail::Syntax::Parser` | `@fluent/syntax` Parser | Full AST parsing |
| `Foxtail::Syntax::Serializer` | `@fluent/syntax` serialize | AST to FTL |
