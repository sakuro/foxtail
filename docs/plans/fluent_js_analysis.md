# fluent.js Architecture Analysis

## 📁 Source File Structure

### Core Components
```
fluent.js/fluent-syntax/src/
├── ast.ts         # AST node class hierarchy  
├── parser.ts      # Main FluentParser class
├── stream.ts      # Character stream processing
├── errors.ts      # Error definitions
├── visitor.ts     # AST visitor pattern
├── serializer.ts  # AST → string conversion
└── index.ts       # Public API exports
```

### Test Data Structure
```
fluent.js/fluent-syntax/test/fixtures_structure/
├── *.ftl         # FTL source files (120+ cases)
├── *.json        # Expected AST JSON output
└── [paired files for each test case]
```

## 🏗️ AST Architecture

### Class Hierarchy
```
BaseNode (abstract)
├── equals(other, ignoredFields) 
├── clone()
└── SyntaxNode (abstract) 
    ├── span?: Span
    ├── addSpan(start, end)
    └── [All concrete AST nodes inherit from this]
```

### Core AST Node Types

#### **Top Level**
- `Resource` - Root node containing Entry[]
- `Entry` = `Message | Term | Comments | Junk`

#### **Content Nodes**
```typescript
Message {
  type: "Message"
  id: Identifier
  value: Pattern | null
  attributes: Attribute[]
  comment: Comment | null
}

Term {
  type: "Term"  
  id: Identifier
  value: Pattern        // Required (unlike Message)
  attributes: Attribute[]
  comment: Comment | null
}

Pattern {
  type: "Pattern"
  elements: PatternElement[]  // TextElement | Placeable
}
```

#### **Expression System**
```typescript
// Expression hierarchy
Expression = InlineExpression | SelectExpression

InlineExpression = 
  | StringLiteral | NumberLiteral
  | FunctionReference | MessageReference 
  | TermReference | VariableReference
  | Placeable

// Key classes
Placeable {
  type: "Placeable"
  expression: Expression
}

SelectExpression {
  type: "SelectExpression"
  selector: InlineExpression
  variants: Variant[]
}
```

#### **Identifiers & References**
```typescript
Identifier {
  type: "Identifier"
  name: string
}

MessageReference {
  type: "MessageReference" 
  id: Identifier
  attribute: Identifier | null
}

TermReference {
  type: "TermReference"
  id: Identifier
  attribute: Identifier | null
  arguments: CallArguments | null
}
```

## 🔧 Parser Architecture

### FluentParser Class Structure
```typescript
class FluentParser {
  withSpans: boolean
  
  // Decorated parsing methods (withSpan applied)
  getComment, getMessage, getTerm, getAttribute,
  getIdentifier, getVariant, getNumber, getPattern,
  getTextElement, getPlaceable, getExpression, etc.
  
  // Main API
  parse(source: string): Resource
  parseEntry(source: string): Entry
}
```

### Key Parser Methods Pattern
```typescript
// Method naming pattern: get[NodeType] 
getComment(ps: FluentParserStream): Comment | null
getMessage(ps: FluentParserStream): Message | null  
getTerm(ps: FluentParserStream): Term | null
getPattern(ps: FluentParserStream): Pattern | null
// ... etc
```

### Span Decoration System
```typescript
function withSpan<T>(fn: ParseFn<T>): ParseFn<T> {
  return function(ps, ...args) {
    if (!this.withSpans) return fn.call(this, ps, ...args);
    
    const start = ps.index;
    const node = fn.call(this, ps, ...args);
    if (!node.span) {
      node.addSpan(start, ps.index);
    }
    return node;
  }
}
```

## 📡 Stream Processing

### FluentParserStream Class
```typescript
class FluentParserStream extends ParserStream {
  // Core navigation
  currentChar(): string
  currentPeek(): string  
  next(): string
  peek(): string
  
  // Position management
  index: number
  peekOffset: number
  resetPeek(offset = 0)
  skipToPeek()
  
  // Special fluent parsing
  peekBlankInline(): string
  skipBlankBlock(): string[]
  skipBlankInline(): string
  peekLineWS(): string
}
```

### CRLF Handling
- **Critical**: CRLF (`\r\n`) treated as single `\n` character
- `charAt(offset)` returns `\n` for CRLF sequences
- Index management accounts for CRLF as single unit

### Special Characters
```typescript
const EOL = "\n";
const EOF = undefined;
const SPECIAL_LINE_START_CHARS = ["}", ".", "[", "*"];
```

## 🚨 Critical Implementation Details

### Comment Attachment Logic
```typescript
// Comments attach to Messages/Terms if:
// 1. Comment is Regular (not Group/Resource)
// 2. NO blank lines between comment and message/term
// 3. Next entry is successfully parsed Message/Term

if (entry instanceof Comment && blankLines.length === 0 && ps.currentChar()) {
  lastComment = entry; // Stash for next iteration
  continue;
}

if (lastComment) {
  if (entry instanceof Message || entry instanceof Term) {
    entry.comment = lastComment;
    // Extend span to include comment
    if (withSpans) entry.span.start = lastComment.span.start;
  } else {
    entries.push(lastComment); // Standalone comment
  }
  lastComment = null;
}
```

### Error Handling Strategy
- Parse errors collected in `ParseError` objects
- Unparseable content becomes `Junk` nodes
- `Junk` contains original content + error annotations
- Parser continues after errors (doesn't throw)

## 🔍 Key Parsing Patterns

### Entry Parsing Flow
```
1. skipBlankBlock()           # Skip leading whitespace
2. while (ps.currentChar())   # Process all characters
3.   entry = getEntryOrJunk() # Parse or create Junk
4.   blankLines = skipBlankBlock()
5.   [Comment attachment logic]
6.   entries.push(entry)
```

### Pattern Parsing Strategy
- Text elements collected until special characters
- Placeables (`{...}`) parsed recursively  
- Multiline handling with indentation normalization
- Escape sequence processing in StringLiterals

### Expression Precedence
1. Literals (`"string"`, `123`)
2. References (`$var`, `message`, `-term`) 
3. Function calls (`FUNC()`)
4. Placeables (`{expr}`)
5. Select expressions (`{selector -> ...}`)

## 🎯 Ruby Translation Priority

### High Priority (Core Functionality)
1. **FluentParserStream** - Character navigation + CRLF handling
2. **AST base classes** - BaseNode, SyntaxNode with span support
3. **Core parsing methods** - getComment, getMessage, getTerm
4. **Pattern system** - TextElement, Placeable parsing
5. **Entry parsing loop** - Main parse() method structure

### Medium Priority (Advanced Features)  
6. **Expression parsing** - SelectExpression, Functions, References
7. **Error handling** - ParseError, Junk creation
8. **Comment attachment** - Complex attachment logic

### Lower Priority (Polish)
9. **Visitor pattern** - AST traversal utilities
10. **Serialization** - AST → string conversion

## 🔧 Critical Ruby Adaptations Needed

### Language Differences
```ruby
# TypeScript → Ruby mappings

# Truthiness (CRITICAL!)
if (str)          → if !str.empty?     # "" is truthy in Ruby!  
if (arr.length)   → if !arr.empty?     # 0 is truthy in Ruby!
if (char)         → if char && char != EOF  # undefined → nil

# Array access
arr[999] || null  → arr[999]           # nil for out of bounds
arr?.length       → arr&.length        # Safe navigation 

# String/Char handling  
char === undefined → char.nil?         # EOF detection
str.charAt(i)     → str[i]             # Character access
String.fromCodePoint → char.chr       # Unicode handling

# Class patterns
new AST.Message() → AST::Message.new() # Namespace syntax
instanceof Class  → is_a?(Class)       # Type checking
```

### Method Naming Conventions
```ruby
# TypeScript → Ruby preferred style
getComment()    → parse_comment() 
getMessage()    → parse_message()
currentChar()   → current_char()
skipBlankBlock()→ skip_blank_block()
```

## 📊 Test Strategy

### Fixture Validation Approach
1. **Load .ftl/.json pairs** - 120+ test cases
2. **Parse .ftl with Ruby parser** - Generate actual AST
3. **Convert to JSON format** - Match fluent.js output
4. **Deep comparison** - Report differences
5. **Iterative refinement** - Fix discrepancies

### Success Metrics
- **Structure match**: 100% identical JSON output
- **Span accuracy**: Position information matches exactly  
- **Error handling**: Same error codes and messages
- **Performance**: Reasonable speed (within 5x of fluent.js)

---

*This analysis provides the foundation for faithful Ruby translation of fluent.js parser logic.*