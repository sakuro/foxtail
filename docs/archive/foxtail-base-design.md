# Foxtail: Ruby Implementation of Project Fluent

## Overview

Foxtail is a Ruby gem that provides a complete implementation of Project Fluent, a localization framework designed to unleash the expressive power of natural language. This document outlines the base design and architecture for the gem.

## Design Goals

1. **Compatibility**: Full compatibility with Fluent Translation List (FTL) format and existing Fluent implementations
2. **Ruby Idioms**: Provide Ruby-native APIs that feel natural to Ruby developers
3. **Performance**: Efficient parsing and message formatting for production use
4. **Extensibility**: Support for custom functions and Rails integration
5. **Error Handling**: Graceful degradation and comprehensive error reporting

## Core Use Cases

### 1. Basic FTL Translation
```ruby
# Load and use FTL files
bundle = Foxtail::Bundle.new("ja")
bundle.add_resource(File.read("locales/ja/messages.ftl"))

# Format messages with variables
message = bundle.format_message("welcome", { name: "田中さん" })
# => "こんにちは、田中さん！"
```

### 2. Rails Application Integration
```ruby
# Configuration
Foxtail.configure do |config|
  config.locales_path = Rails.root.join("config/locales")
  config.fallback_locale = :en
end

# Helper usage in controllers/views
class ApplicationController
  include Foxtail::Rails::Helper
  
  def index
    @welcome = ft("welcome", name: current_user.name)
  end
end
```

### 3. Advanced Language Features
```ruby
# Pluralization and selection expressions
# FTL: emails = { $count -> [0] No emails [one] 1 email *[other] { $count } emails }
bundle.format_message("emails", { count: 5 })
# => "5 emails"

# Terms reuse
# FTL: -brand = Firefox
#      welcome = Welcome to { -brand }
bundle.format_message("welcome")
# => "Welcome to Firefox"
```

### 4. Language Negotiation
```ruby
# Automatic language selection based on user preferences
negotiator = Foxtail::LanguageNegotiator.new(["ja", "en"])
locale = negotiator.best_match(request.accept_language)
bundle = Foxtail::Bundle.new(locale)
```

### 5. Error Handling
```ruby
begin
  message = bundle.format_message("missing-key")
rescue Foxtail::MessageNotFoundError => e
  Rails.logger.warn("Missing translation: #{e.message}")
  message = "??#{e.message_id}??"
end
```

### 6. Custom Functions
```ruby
bundle.add_function("CURRENCY") do |args, opts|
  Money.new(args[0], opts[:currency] || "USD").format
end

# FTL: price = Price: { CURRENCY($amount, currency: "USD") }
```

## Core Architecture

### Primary Classes

#### `Foxtail::Bundle`
- **Purpose**: Main interface for loading and formatting messages
- **Responsibilities**:
  - Load FTL resources from files/strings
  - Manage message lookup and formatting
  - Handle fallback locales
  - Manage custom functions

#### `Foxtail::Parser`
- **Purpose**: Parse FTL syntax into Abstract Syntax Tree (AST)
- **Responsibilities**:
  - Implement FTL EBNF grammar
  - Generate AST nodes
  - Handle parsing errors and junk recovery
  - Maintain source position information

#### `Foxtail::Resource`
- **Purpose**: Represent a parsed FTL resource
- **Responsibilities**:
  - Store messages, terms, and comments
  - Provide message lookup functionality
  - Handle resource metadata

#### `Foxtail::Message`
- **Purpose**: Represent individual translatable messages
- **Responsibilities**:
  - Store message pattern and attributes
  - Format patterns with variable substitution
  - Handle select expressions and pluralization

#### `Foxtail::LanguageNegotiator`
- **Purpose**: Handle language preference negotiation
- **Responsibilities**:
  - Parse Accept-Language headers
  - Find best matching available locale
  - Implement language matching algorithms

#### `Foxtail::Rails::Helper`
- **Purpose**: Rails framework integration
- **Responsibilities**:
  - Provide view helpers
  - Handle locale switching
  - Integration with Rails I18n

### AST Structure

Following fluent.js patterns, the AST will include:

- **Resource**: Top-level container
- **Message/Term**: Translation entries
- **Pattern**: Text with placeables
- **Expression**: Variables, selectors, function calls
- **Literal**: Strings, numbers
- **Span**: Source position tracking

### Error Handling Strategy

1. **Parse Errors**: Collect and report syntax errors while continuing parsing
2. **Runtime Errors**: Graceful degradation with fallback text
3. **Missing Messages**: Configurable behavior (exception, fallback, placeholder)
4. **Function Errors**: Isolate custom function failures

## Implementation Phases

### Phase 1: Core Parser
- Implement FTL EBNF grammar
- Create AST node classes
- Basic parsing with error recovery
- Test against fluent.js fixtures

### Phase 2: Message Formatting
- Pattern evaluation engine
- Variable substitution
- Basic select expressions
- Simple function calls

### Phase 3: Advanced Features
- Complex selectors and pluralization
- Custom function registry
- Language negotiation
- Error handling improvements

### Phase 4: Framework Integration
- Rails helpers and configuration
- Performance optimizations
- Comprehensive documentation
- Production readiness

## Testing Strategy

1. **Grammar Compliance**: Use fluent.js test fixtures (126 test cases)
2. **API Compatibility**: Cross-reference with fluent.js behavior
3. **Performance**: Benchmark against realistic data sets
4. **Integration**: Test with Rails applications
5. **Error Cases**: Comprehensive error handling validation

## Dependencies

- **Standard Library**: String, File, JSON handling
- **Optional**: Rails integration (when available)
- **Development**: RSpec, performance profiling tools

## Success Criteria

1. Parse all valid FTL files correctly
2. Generate identical AST to fluent.js reference implementation
3. Handle all fluent.js test fixtures
4. Provide intuitive Ruby API
5. Support production Rails applications
6. Maintain good performance characteristics

This design provides a solid foundation for implementing a complete, Ruby-native Fluent localization system.