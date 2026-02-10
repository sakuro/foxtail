# Foxtail Runtime Architecture

## Overview

`foxtail-runtime` provides runtime parsing and formatting. It exposes the `Foxtail` module and is responsible for bundle parsing, message resolution, and ICU4X-backed formatting.

## Bundle Parser (`Bundle::Parser`) → `Bundle::Parser::AST`

- **Purpose**: Lightweight runtime parser optimized for message formatting
- **Output**: Runtime AST directly usable by `Bundle`
- **AST**: Immutable `Data` classes, patterns simplified to `String` or `Array`, no spans
- **Use Cases**: Runtime message loading via `Resource`

## Core Components

### Resource Layer

| Component | File | Responsibility |
|-----------|------|----------------|
| `Resource` | `lib/foxtail/resource.rb` | Public parsing API for runtime |

`Resource` wraps `Bundle::Parser`, providing `from_string` and `from_file` methods.

### Bundle Layer

| Component | File | Responsibility |
|-----------|------|----------------|
| `Bundle` | `lib/foxtail/bundle.rb` | Message storage and formatting |
| `Bundle::Parser` | `lib/foxtail/bundle/parser.rb` | Runtime FTL parsing |
| `Bundle::Parser::AST` | `lib/foxtail/bundle/parser/ast.rb` | Runtime `Data` classes |
| `Resolver` | `lib/foxtail/bundle/resolver.rb` | Pattern evaluation |
| `Scope` | `lib/foxtail/bundle/scope.rb` | Variable context |

### Function Layer

| Component | File | Responsibility |
|-----------|------|----------------|
| `Function` | `lib/foxtail/function.rb` | NUMBER, DATETIME via `icu4x` |

## Runtime Behavior

Usage examples, AST details, error handling, and ICU4X integration are documented in [bundle-system.md](bundle-system.md).

## File Structure

```
lib/foxtail/
├── bundle/
│   ├── parser.rb              # Bundle::Parser (runtime)
│   ├── parser/
│   │   └── ast.rb             # Bundle::Parser::AST (Data classes)
│   ├── resolver.rb            # Resolver
│   └── scope.rb               # Scope
├── resource.rb                # Resource
├── bundle.rb                  # Bundle
└── function.rb                # NUMBER, DATETIME
```

## fluent.js Correspondence

| Foxtail | fluent.js | Purpose |
|---------|-----------|---------|
| `Foxtail::Bundle::Parser` | `@fluent/bundle` FluentResource | Runtime parsing |
| `Foxtail::Bundle` | `@fluent/bundle` FluentBundle | Message formatting |
