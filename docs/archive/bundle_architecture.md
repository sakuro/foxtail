# Foxtail Bundle Architecture Design

## Overview

This document outlines the architecture design for the Foxtail Bundle system, which is a faithful Ruby port of the fluent-bundle JavaScript implementation. The Bundle system is responsible for runtime message formatting and localization.

## Design Principles

1. **Faithful to fluent-bundle**: Follow the fluent-bundle/src structure and behavior
2. **Parser Reuse**: Leverage existing Parser::AST instead of implementing a separate parser
3. **Performance**: Optimize for runtime message resolution speed
4. **Separation of Concerns**: Clear distinction between parsing (Parser) and runtime (Bundle)

## Architecture Overview

```
┌─────────────────────────────────────────────────┐
│                User Application                 │
└─────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────┐
│              Foxtail Public API                 │
│                                                 │
│  Bundle ◄── Resource ◄── Function             │
└─────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────┐
│            Bundle Internal System               │
│                                                 │
│  Bundle::AST  Bundle::Resolver  Bundle::Scope  │
└─────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────┐
│              Parser System                      │
│                                                 │
│         Parser ◄── Parser::AST                 │
└─────────────────────────────────────────────────┘
```

## Class Structure

### File Organization

```
lib/foxtail/
├── bundle.rb           # Foxtail::Bundle (main class)
├── bundle/
│   ├── ast.rb         # Foxtail::Bundle::AST (internal)
│   ├── resolver.rb    # Foxtail::Bundle::Resolver (internal)
│   └── scope.rb       # Foxtail::Bundle::Scope (internal)
├── resource.rb        # Foxtail::Resource (public API)
├── function.rb        # Foxtail::Function (public API)
├── parser.rb          # Foxtail::Parser (development tool)
├── parser/
│   ├── ast.rb         # Foxtail::Parser::AST
│   └── ast/           # Parser::AST::* classes
├── stream.rb          # Foxtail::Stream (to be moved to Parser::Stream)
├── errors.rb          # Error definitions
└── version.rb         # Version definition
```

## Component Specifications

### 1. Foxtail::Bundle

**Purpose**: Main runtime class for message formatting

**Corresponds to**: fluent-bundle/src/bundle.ts

```ruby
module Foxtail
  class Bundle
    attr_reader :locales, :messages, :terms, :functions
    
    def initialize(locales, options = {})
      @locales = Array(locales)
      @messages = {}  # id → Bundle::AST Message
      @terms = {}     # id → Bundle::AST Term  
      @functions = options[:functions] || {}
      @use_isolating = options.fetch(:use_isolating, true)
      @transform = options[:transform]
    end
    
    def add_resource(resource, options = {})
    def has_message?(id)
    def get_message(id)
    def format(id, args = {})
    def format_pattern(pattern, args = {})
  end
end
```

### 2. Foxtail::Resource

**Purpose**: Parse FTL source and convert to Bundle::AST

**Corresponds to**: fluent-bundle/src/resource.ts

```ruby
module Foxtail
  class Resource
    attr_reader :entries, :errors
    
    def initialize(entries)
      @entries = entries
      @errors = []
    end
    
    def self.from_string(source, options = {})
    def self.from_file(path, options = {})
  end
end
```

**Key Decision**: Use Parser::AST instead of implementing a regex-based parser
- Pros: Reuse existing 99% compatible parser, single parser to maintain
- Cons: Slightly slower (estimated 1.3x), two-step process (parse then convert)

### 3. Foxtail::Function

**Purpose**: Built-in formatting functions (NUMBER, DATETIME, etc.)

**Corresponds to**: fluent-bundle/src/builtins.ts

```ruby
module Foxtail
  module Function
    NUMBER = lambda do |value, options = {}|
      # Number formatting logic
    end
    
    DATETIME = lambda do |value, options = {}|
      # DateTime formatting logic
    end
    
    DEFAULTS = {
      "NUMBER" => NUMBER,
      "DATETIME" => DATETIME
    }.freeze
  end
end
```

### 4. Foxtail::Bundle::AST

**Purpose**: Lightweight runtime AST representation

**Corresponds to**: fluent-bundle/src/ast.ts

```ruby
module Foxtail
  class Bundle
    module AST
      # Builder methods for AST nodes
      def self.str(value)           # {type: "str", value: "..."}
      def self.num(value)           # {type: "num", value: 42}
      def self.var(name)            # {type: "var", name: "..."}
      def self.term(name, attr: nil) # {type: "term", name: "..."}
      def self.mesg(name, attr: nil) # {type: "mesg", name: "..."}
      def self.func(name, args: [])  # {type: "func", name: "..."}
      def self.select(selector, variants, star: 0)
      
      # Converter from Parser::AST to Bundle::AST
      class Converter
        def initialize(options = {})
        def convert_resource(parser_resource)
        def convert_message(parser_message)
        def convert_term(parser_term)
      end
    end
  end
end
```

**Design Choice**: Hash-based representation instead of dry-types
- Lightweight runtime representation
- Direct correspondence to TypeScript types
- No runtime validation overhead

### 5. Foxtail::Bundle::Resolver

**Purpose**: Pattern resolution engine

**Corresponds to**: fluent-bundle/src/resolver.ts

```ruby
module Foxtail
  class Bundle
    class Resolver
      def initialize(bundle)
        @bundle = bundle
      end
      
      def resolve_pattern(pattern, scope)
      def resolve_expression(expr, scope)
      
      private
      def resolve_variable(expr, scope)
      def resolve_term(expr, scope)
      def resolve_message(expr, scope)
      def resolve_select(expr, scope)
      def resolve_function(expr, scope)
    end
  end
end
```

### 6. Foxtail::Bundle::Scope

**Purpose**: Variable scope and state management during resolution

**Corresponds to**: fluent-bundle/src/scope.ts

```ruby
module Foxtail
  class Bundle
    class Scope
      attr_reader :bundle, :args, :locals, :errors, :dirty
      
      def initialize(bundle, args = {})
        @bundle = bundle
        @args = args      # External variables
        @locals = {}      # Local variables (in functions)
        @errors = []      # Error collection
        @dirty = Set.new  # Circular reference detection
      end
      
      def get(name)
      def set_local(name, value)
      def track(id)      # Track for circular references
      def release(id)
    end
  end
end
```

## AST Type System

Following fluent-bundle/src/ast.ts TypeScript definitions:

### Pattern Types
```typescript
type Pattern = string | ComplexPattern
type ComplexPattern = Array<PatternElement>
type PatternElement = string | Expression
```

### Expression Types
```typescript
type Expression =
  | SelectExpression
  | VariableReference
  | TermReference
  | MessageReference
  | FunctionReference
  | Literal
```

### Ruby Hash Representation Examples

```ruby
# StringLiteral
{ type: "str", value: "Hello" }

# NumberLiteral
{ type: "num", value: 42.0, precision: 2 }

# VariableReference
{ type: "var", name: "username" }

# MessageReference
{ type: "mesg", name: "hello", attr: "title" }

# TermReference
{ type: "term", name: "brand" }

# SelectExpression
{
  type: "select",
  selector: { type: "var", name: "count" },
  variants: [
    { key: { type: "num", value: 0.0 }, value: "none" },
    { key: { type: "str", value: "one" }, value: "one item" },
    { key: { type: "str", value: "other" }, value: "many items" }
  ],
  star: 2  # Index of default variant
}

# Message
{
  id: "greeting",
  value: ["Hello, ", { type: "var", name: "name" }, "!"],
  attributes: {}
}
```

## API Usage Examples

### Basic Usage

```ruby
# Create resource
resource = Foxtail::Resource.from_string(<<~FTL)
  hello = Hello, {$name}!
  emails = You have {$count ->
    [0] no emails
    [one] one email
   *[other] {$count} emails
  }.
FTL

# Create bundle
bundle = Foxtail::Bundle.new("en-US", 
  functions: Foxtail::Function::DEFAULTS
)

# Add resource
bundle.add_resource(resource)

# Format messages
bundle.format("hello", name: "World")     # => "Hello, World!"
bundle.format("emails", count: 0)         # => "You have no emails."
```

### Advanced Usage

```ruby
# Direct pattern formatting (low-level API)
message = bundle.get_message("hello")
errors = []
result = bundle.format_pattern(message[:value], { name: "Alice" }, errors)

# Custom functions
my_functions = Foxtail::Function::DEFAULTS.merge({
  "UPPER" => lambda { |text, _opts| text.to_s.upcase }
})

bundle = Foxtail::Bundle.new("en", functions: my_functions)
```

## Implementation Strategy

### Phase 1: Core Components
1. Implement Bundle::AST with Converter
2. Implement Resource with Parser integration
3. Implement basic Bundle class

### Phase 2: Resolution Engine
1. Implement Resolver for pattern resolution
2. Implement Scope for variable management
3. Handle circular references and errors

### Phase 3: Advanced Features
1. Implement Function module with NUMBER/DATETIME
2. Add transform support
3. Add isolating support

### Phase 4: Testing and Optimization
1. Port fluent-bundle test suite
2. Performance optimization
3. Error handling improvements

## Testing Strategy

Reference fluent-bundle/test for test cases:
- constructor_test.js → Bundle initialization
- patterns_test.js → Pattern resolution
- select_expressions_test.js → SelectExpression handling
- functions_test.js → Function calls
- errors_test.js → Error handling

## Performance Considerations

### Parser Reuse Trade-off
- **fluent-bundle approach**: Regex-based, direct to Bundle::AST
- **Foxtail approach**: Parser::AST → Bundle::AST conversion
- **Performance impact**: ~1.3x slower for parsing (acceptable)
- **Benefits**: Single parser, 99% compatibility proven

### Optimization Opportunities
1. Cache converted AST nodes
2. Optimize Converter for common patterns
3. Lazy evaluation where possible

## Open Questions

1. Should we implement memoization like fluent-bundle?
2. How to handle Intl API differences between JavaScript and Ruby?
3. Should transform functions be supported from day one?

## References

- [fluent-bundle source](https://github.com/projectfluent/fluent.js/tree/main/fluent-bundle)
- [fluent-bundle tests](https://github.com/projectfluent/fluent.js/tree/main/fluent-bundle/test)
- [Fluent Syntax Guide](https://projectfluent.org/fluent/guide/)