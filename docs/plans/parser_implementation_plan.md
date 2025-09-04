# Parser Implementation Plan

## 🎯 Goal
Achieve 100% identical AST generation with fluent.js test fixtures:
- `fluent.js/fluent-syntax/test/fixtures_structure/` (120+ test cases)
- `fluent.js/fluent-syntax/test/fixtures_reference/`

## 🔧 Implementation Strategy
**Direct Translation**: Faithfully translate fluent.js TypeScript Parser to Ruby
- Source: `fluent.js/fluent-syntax/src/`
- Focus on exact behavior replication
- Account for TypeScript ↔ Ruby language differences

## 📊 Critical Language Differences

### Truthiness
| TypeScript (falsy) | Ruby (falsy) | Notes |
|-------------------|--------------|-------|
| `0` | `false`, `nil` | Ruby: `0` is truthy! |
| `""` | `false`, `nil` | Ruby: `""` is truthy! |
| `null`, `undefined` | `nil` | Only `nil` and `false` are falsy in Ruby |

### Array Access
| TypeScript | Ruby | Notes |
|------------|------|-------|
| `arr[999]` → `undefined` | `arr[999]` → `nil` | Out of bounds behavior |
| `arr.length` | `arr.length` | Same |

### String/Number Conversion
| TypeScript | Ruby | Notes |
|------------|------|-------|
| `+"123"` → `123` | `"123".to_i` → `123` | Explicit conversion needed |
| `String(123)` → `"123"` | `123.to_s` → `"123"` | Different method names |

## 📋 Implementation Phases

### Phase 1: Foundation Analysis
1. **AST Structure Analysis** (`ast.ts`)
   - BaseNode hierarchy
   - Node types and properties
   - Span handling
   
2. **Parser Core Analysis** (`parser.ts`)
   - FluentParser class structure
   - Parse methods and flow
   - withSpan decorator pattern
   
3. **Supporting Systems** (`stream.ts`, `errors.ts`)
   - FluentParserStream class
   - Error types and codes
   - EOF/EOL handling

### Phase 2: Test Environment
4. **Fixture Comparison Framework**
   - Automated .ftl → .json comparison
   - AST diff reporting
   - Progress tracking

5. **Baseline Measurement**
   - Initial compatibility assessment
   - Identify critical gaps

### Phase 3: Ruby Implementation
6. **AST Classes (Ruby)**
   - Mirror TypeScript class hierarchy
   - Implement equals/to_h methods
   - Proper span handling
   
7. **Stream Processor (Ruby)**
   - Character stream management
   - Position tracking
   - EOF/EOL detection
   
8. **Parser Core (Ruby)**
   - Method-by-method translation
   - Maintain exact parsing logic
   - Handle Ruby-specific idioms
   
9. **Error Handling (Ruby)**
   - Error code constants
   - ParseError class
   - Annotation system

### Phase 4: Validation & Refinement
10. **100% Compatibility Achievement**
    - Fix AST structure differences
    - Correct span position calculations
    - Validate error messages and codes

## 🚨 Critical Success Factors
- **Exact Logic Replication**: Don't optimize, translate faithfully
- **Language Difference Awareness**: Test truthiness, array access carefully
- **Continuous Validation**: Run fixture tests after each major change
- **Methodical Approach**: Complete each phase before moving to next

## 📁 File Structure Plan
```
lib/foxtail/
├── ast.rb          # AST node classes
├── parser.rb       # Main FluentParser class  
├── stream.rb       # FluentParserStream class
├── errors.rb       # Error classes and codes
└── version.rb      # Existing version file
```

## 🧪 Testing Strategy
1. **Unit Tests**: Individual parser methods
2. **Integration Tests**: Complete .ftl parsing
3. **Compatibility Tests**: fluent.js fixture comparison
4. **Regression Tests**: Prevent backsliding

## 📊 Success Metrics
- **Primary**: 100% identical AST generation (fixtures_structure)
- **Secondary**: 100% identical AST generation (fixtures_reference)
- **Tertiary**: Performance within 2x of original Ruby parser