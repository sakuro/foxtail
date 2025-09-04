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

## 🏗️ Architecture Decisions

### Class Design Decision (2024)
**TypeScript → Ruby Mapping:**
- `ParserStream` (base class) → *Skipped* (unnecessary abstraction)
- `FluentParserStream` → `Foxtail::Stream` (direct mapping)

**Rationale:**
- **Simplification**: Avoid unnecessary base class since Ruby implementation only needs FluentParserStream functionality
- **Direct Translation**: Map fluent.js's primary stream class directly to Ruby equivalent
- **Ruby Conventions**: Use `Foxtail::` namespace for clean organization
- **Efficiency**: Eliminate inheritance overhead for unused base functionality

### Implementation Status
- ✅ **Test Framework**: 62 fixture validation system established
- ✅ **Baseline Measurement**: 2/62 perfect matches (3.2%) with placeholder parser
- 🚧 **Ruby Implementation**: Starting with `Foxtail::Stream` class

## 📁 File Structure Plan
```
lib/foxtail/
├── ast.rb          # AST node classes
├── parser.rb       # Main FluentParser class  
├── stream.rb       # Foxtail::Stream class (FluentParserStream equivalent)
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

## 🎯 Implementation Progress

### Completed ✅
- [x] **Project Analysis** (fluent.js architecture study)
- [x] **Test Framework** (62-fixture automated comparison)
- [x] **Baseline Measurement** (2/62 matches with placeholder)
- [x] **Architecture Design** (class mapping decisions)

### In Progress 🚧
- [ ] **Foxtail::Stream** (character stream processing)
- [ ] **AST Base Classes** (BaseNode, SyntaxNode hierarchy)
- [ ] **Core Parser Methods** (entry parsing loop)

### Planned 📋
- [ ] **Pattern System** (TextElement, Placeable parsing)
- [ ] **Expression Parsing** (SelectExpression, References)
- [ ] **Error Handling** (ParseError, Junk creation)
- [ ] **Comment System** (attachment logic)
- [ ] **Final Validation** (100% fixture compatibility)

### Milestone Targets
- **Phase 1 Complete**: Basic parsing (10+ fixtures passing)
- **Phase 2 Complete**: Advanced features (30+ fixtures passing)
- **Phase 3 Complete**: Error handling (50+ fixtures passing)
- **Final Goal**: 62/62 fixtures passing (100% compatibility)