# Foxtail Implementation Decisions

## Major Design Decisions

### 1. Parser Reuse vs. Separate Parser

**Decision**: Reuse existing Parser::AST with conversion to Bundle::AST

**Alternatives Considered**:
1. Implement regex-based parser like fluent-bundle (faithful port)
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
- ❌ Not 100% faithful to fluent-bundle implementation

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

### From Prototype to Production

1. **Current State**: Parser at 99% compatibility
2. **Next Step**: Bundle implementation with tests
3. **Validation**: Port fluent-bundle test suite
4. **Optimization**: Profile and optimize hot paths
5. **Documentation**: API docs and guides

### Breaking Changes

If we need to change the API:
1. Deprecate old methods with warnings
2. Provide migration guide
3. Support both APIs for one major version
4. Remove deprecated code in next major version