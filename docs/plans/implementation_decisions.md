# Foxtail Implementation Decisions

## Major Design Decisions

### 1. Parser Reuse vs. Separate Parser

**Decision**: Reuse existing Parser::AST with conversion to Bundle::AST

**Alternatives Considered**:
1. Implement regex-based parser like fluent-bundle (direct port)
2. Use Parser::AST and convert to Bundle::AST (chosen)

**Rationale**:
- Parser already achieves 99% fluent.js compatibility
- Avoid maintaining two separate parsers
- DRY principle - don't repeat yourself
- Performance impact is acceptable (~1.3x slower, only at resource load time)
- Easier to maintain consistency

**Trade-offs**:
- ✅ Single source of truth for parsing logic
- ✅ Bug fixes apply to both development and runtime
- ✅ Already proven compatibility
- ❌ Slightly slower resource loading
- ❌ Not 100% compatible with fluent-bundle implementation

### 2. Bundle::AST Type System

**Decision**: Use Hash-based lightweight AST

**Alternatives Considered**:
1. dry-types with full type validation
2. Class-based AST nodes
3. Hash-based representation (chosen)

**Rationale**:
- Direct correspondence to fluent-bundle/ast.ts TypeScript types
- No runtime validation overhead
- Simple and performant
- Easy to debug with `pp` and `inspect`

**Example**:
```ruby
# Simple hash representation
{ type: "var", name: "username" }

# Instead of
class VariableReference < Dry::Struct
  attribute :type, Types::String.enum("var")
  attribute :name, Types::String
end
```

### 3. Class Organization

**Decision**: Bundle internals as nested classes, public APIs at top level

**Structure**:
```
Foxtail::Bundle           # Public API
Foxtail::Resource         # Public API
Foxtail::Functions        # Public API
Foxtail::Bundle::AST      # Internal
Foxtail::Bundle::Resolver # Internal
Foxtail::Bundle::Scope    # Internal
```

**Rationale**:
- Clear separation between public API and internals
- Resource is frequently used by users, deserves top-level access
- Bundle-specific internals are properly namespaced
- Functions need to be easily accessible for customization

### 4. Converter as Instance

**Decision**: Use instance methods for Converter instead of class methods

**Example**:
```ruby
# Instance-based (chosen)
converter = Bundle::AST::Converter.new(options)
converter.convert(ast)

# Instead of class methods
Bundle::AST::Converter.convert(ast)
```

**Rationale**:
- Better flexibility for configuration
- Easier to test with dependency injection
- Can maintain state (errors, warnings)
- More extensible for future needs

### 5. Error Handling Strategy

**Decision**: Collect errors in array, continue processing

**Implementation**:
```ruby
def format_pattern(pattern, args = nil, errors = nil)
  errors ||= []
  # Process and collect errors
  errors << SomeError.new("message")
  # Continue processing
end
```

**Rationale**:
- Matches fluent-bundle behavior
- Allows partial success
- Users can inspect all errors
- Non-breaking for simple use cases

### 6. CLDR Integration Strategy

**Decision**: Full CLDR implementation with Ruby-native formatters

**Implementation**:
- `Foxtail::CLDR::NumberFormats` - CLDR-based number formatting
- `Foxtail::CLDR::DateTimeFormats` - CLDR-based datetime formatting
- `Foxtail::CLDR::PluralRules` - CLDR plural rule engine
- Custom NumberFormatter/DateTimeFormatter classes

**Rationale**:
- Go beyond basic fluent-bundle functionality
- Provide production-ready i18n capabilities
- Ruby-specific formatting instead of JavaScript Intl API
- Support multiple locales with proper fallbacks

**Trade-offs**:
- ✅ Full-featured localization system
- ✅ Ruby-native formatting with proper locale support
- ✅ CLDR-compliant plural rules
- ❌ Larger gem size
- ❌ More complex dependency chain

### 7. Functions Architecture Evolution

**Decision**: Class-based Functions instead of simple lambdas

**Original Plan**:
```ruby
Functions::NUMBER = lambda do |value, options = {}|
  # Simple formatting
end
```

**Final Implementation**:
```ruby
Functions::DEFAULTS = {
  "NUMBER" => NumberFormatter.new,
  "DATETIME" => DateTimeFormatter.new
}
```

**Rationale**:
- Stateful formatters for CLDR integration
- Better locale handling and caching
- Extensible configuration
- Performance benefits (cached CLDR data)
- Support for complex formatting options

### 8. Compatibility Achievement Results

**Final Status**: 99.0% fluent.js compatibility (97/98 tests passing)

**Test Results**:
- Structure Fixtures: 62/62 (100%) ✅
- Reference Fixtures: 35/36 (97.2%) ⚠️

**Remaining Issue**: 
- `leading_dots` fixture - Known fluent.js incompatibility (intentionally skipped by fluent.js)

**Decision**: Accept this limitation as fluent.js itself acknowledges this as incompatible
- This represents the practical maximum achievable compatibility
- Pursuing 100% would require implementing known fluent.js bugs

## Technical Decisions

### AST Conversion Strategy

**Parser::AST → Bundle::AST Conversion Rules**:

1. **Skip Junk entries** - They represent parse errors
2. **Skip Comments** - Not needed at runtime
3. **Flatten TextElements** - Convert to simple strings
4. **Preserve structure** - Keep complex patterns as arrays

### Scope Management

**Three levels of variables**:
1. **Args** - Passed from application
2. **Locals** - Set within functions
3. **Dirty** - Tracking for circular reference detection

### Function Interface

**Lambda-based functions**:
```ruby
Functions::NUMBER = lambda do |value, options = {}|
  # Implementation
end
```

**Rationale**:
- Simple interface
- Easy to test
- Matches JavaScript function style

## Performance Optimizations

### Implemented Optimizations

1. **CLDR Data Caching**
   - Aggressive caching of locale-specific formatting data
   - Number format patterns cached per locale
   - DateTime format patterns cached per locale
   - Plural rules cached and compiled

2. **Parser Performance Decision**
   - **Accepted**: ~1.3x slower parsing for architecture benefits
   - **Trade-off**: Parsing happens at resource load time, not runtime
   - **Benefit**: Runtime message resolution remains fast

3. **Runtime Performance Focus**
   - Optimized Bundle::Resolver for message resolution speed
   - Efficient AST traversal and evaluation
   - String concatenation optimizations

### Planned Optimizations

1. **AST Conversion Caching**
   ```ruby
   @cache[parser_ast.object_id] ||= convert(parser_ast)
   ```

2. **String Pattern Fast Path**
   ```ruby
   return pattern if pattern.is_a?(String)  # Skip processing
   ```

3. **Lazy Term Resolution**
   - Only resolve terms when actually referenced

### Deferred Optimizations

1. **Memoization** - Like fluent-bundle's memoizer
2. **Compiled Patterns** - Pre-compile complex patterns
3. **JIT AST Generation** - Generate AST on demand

## Compatibility Considerations

### Differences from fluent-bundle

1. **Parser**: Using full parser instead of regex-based
2. **Intl API**: Ruby doesn't have Intl, need alternatives
3. **Functions**: Different built-in function implementations

### Maintaining Compatibility

1. **Test Suite**: Port fluent-bundle tests
2. **Fixtures**: Use same test fixtures
3. **Behavior**: Match error handling and edge cases

## Future Considerations

### Potential Enhancements

1. **Streaming Parser** - For very large FTL files
2. **Parallel Resolution** - For multiple messages
3. **WebAssembly Integration** - Use fluent-bundle WASM

### Extension Points

1. **Custom Functions** - Already supported
2. **Transform Functions** - Planned
3. **Custom Resolvers** - Possible with current design

## Dependencies

### Current Dependencies
- `dry-types` and `dry-struct` - Added but may not be used
- Ruby 3.4.5+ - For pattern matching and other features

### Considered but Rejected
- `parslet` - Too heavyweight for our needs
- `regexp_parser` - Not needed with existing Parser
- `i18n` gem integration - Keep Foxtail independent

## Migration Path

### From Prototype to Production ✅ COMPLETED

1. **✅ Parser Implementation**: 99% fluent.js compatibility achieved
2. **✅ Bundle Implementation**: Complete with Resolver, Scope, AST conversion
3. **✅ CLDR Integration**: Full NumberFormatter and DateTimeFormatter
4. **✅ Test Suite**: 97/98 fluent.js compatibility tests passing
5. **✅ Production Ready**: Full Bundle system operational

### Current Status: Production Ready

The implementation has successfully evolved from prototype to production-ready:
- All core functionality implemented
- High fluent.js compatibility achieved
- CLDR integration provides enterprise-grade localization
- Comprehensive test coverage established

### Breaking Changes

If we need to change the API:
1. Deprecate old methods with warnings
2. Provide migration guide
3. Support both APIs for one major version
4. Remove deprecated code in next major version