# Language Guidelines for AI Agents

> **Note**: This document contains examples in multiple languages (Japanese, English) to demonstrate proper language usage patterns. This is intentional for educational purposes, even though project documentation is normally written in English only.

This document defines language usage conventions for different contexts within the project.

## Overview

The project follows a multilingual approach that balances international accessibility with localized communication effectiveness.

## Communication Languages

### AI/Maintainer Chat Communication

**Rule**: Use the user's preferred language for chat interactions.

- **When user writes in Japanese**: Respond in Japanese
- **When user writes in English**: Respond in English  
- **When user writes in other languages**: Match their language when possible
- **Default fallback**: English for unsupported languages

**Examples**:
```
User: "このバグを修正してください"
AI: "バグを修正します。まず問題を確認させてください。"

User: "Fix this bug please"
AI: "I'll fix the bug. Let me first identify the issue."
```

**Rationale**: Effective communication in the user's native language improves understanding and reduces miscommunication.

### Pseudocode and Technical Discussion

**Rule**: Comments within pseudocode blocks may use the user's language, while the pseudocode structure remains universal.

**Example**:
```ruby
# ユーザー認証をチェック
def authenticate_user(credentials)
  # パスワードをハッシュ化して比較
  if hash_password(credentials.password) == stored_hash
    # 認証成功
    return create_session(credentials.user)
  end
  
  # 認証失敗
  raise AuthenticationError
end
```

## Code and Documentation Languages

### Source Code

**Rule**: All source code MUST be written in English.

**Applies to**:
- Variable names, method names, class names
- Function parameters and return values
- Inline code comments
- Code documentation strings

**Examples**:
```ruby
# ✅ Correct
def calculate_performance_score(metrics)
  # Calculate weighted average of performance metrics
  total_weight = metrics.sum(&:weight)
  return 0 if total_weight.zero?
  
  metrics.sum { |metric| metric.value * metric.weight } / total_weight
end

# ❌ Incorrect  
def パフォーマンス計算(メトリクス)
  # 重み付き平均を計算
  合計重み = メトリクス.sum(&:weight)
  return 0 if 合計重み.zero?
  
  # ... rest of method
end
```

### Documentation

**Rule**: All documentation MUST be written in English.

**Applies to**:
- README files
- YARD documentation comments
- API documentation
- Code comments explaining complex logic
- Markdown files in `docs/` directory

**Examples**:
```ruby
# ✅ Correct YARD documentation
# Calculates the optimal cache size based on available memory
# and expected usage patterns.
#
# @param available_memory [Integer] Available memory in bytes
# @param usage_pattern [Symbol] Expected usage pattern (:light, :moderate, :heavy)
# @return [Integer] Recommended cache size in bytes
# @raise [ArgumentError] if available_memory is negative
def calculate_cache_size(available_memory, usage_pattern)
  # Implementation...
end
```

### Issues and Pull Requests

**Rule**: Prefer English for titles and descriptions to maximize visibility and collaboration.

**GitHub Issues**:
- **Title**: English preferred
- **Description**: English preferred, but user's language acceptable
- **Technical details**: English strongly preferred

**Pull Requests**:
- **Title**: English required (follows commit message conventions)
- **Description**: English preferred
- **Code review comments**: English preferred

**Examples**:
```
✅ Preferred
Title: Fix performance regression in cache invalidation
Description: Resolves issue where cache invalidation was O(n²)...

✅ Acceptable  
Title: Fix performance regression in cache invalidation
Description: キャッシュ無効化のパフォーマンス問題を修正しました。
O(n²)のアルゴリズムをO(n)に改善しています。

❌ Avoid
Title: キャッシュの性能問題を修正
Description: [Japanese description]
```

## File and Directory Names

**Rule**: All file and directory names MUST use English.

**Applies to**:
- Source files: `performance_optimizer.rb`
- Test files: `performance_optimizer_spec.rb`  
- Documentation: `installation_guide.md`
- Directories: `lib/`, `spec/`, `docs/`

**Naming Conventions**:
- Use `snake_case` for Ruby files
- Use `kebab-case` for markdown files and directories when appropriate
- Use descriptive, clear English terms

## Rationale

### Why English for Code and Documentation?

1. **International Collaboration**: English serves as the lingua franca of programming
2. **Tool Compatibility**: Most development tools, libraries, and frameworks expect English
3. **Maintainability**: Future maintainers from any background can understand the code
4. **Professional Standards**: Industry standard practice for open source projects
5. **Search and Discovery**: English keywords improve searchability

### Why User's Language for Communication?

1. **Clarity**: Complex technical concepts are often better explained in native language
2. **Efficiency**: Reduces translation overhead and potential misunderstandings
3. **Comfort**: Users feel more comfortable expressing nuanced requirements
4. **Cultural Context**: Some concepts don't translate well and need cultural context

## Implementation Guidelines for AI Agents

### Language Detection

Detect user's preferred language from:
1. First message language
2. Explicit language requests
3. Previous interaction history
4. Default to English if uncertain

### Context Switching

When switching between communication and code:
```
User: "パフォーマンスを改善したい"
AI: "パフォーマンス改善を行います。以下のコードを修正します："

```ruby
def optimize_performance(data)
  # Implement performance optimization
  cached_results = Cache.new
  # ... English comments and code
end
```

AI: "このようにキャッシュを追加してパフォーマンスを向上させました。"
```

### Documentation Generation

When generating documentation:
- Always use English regardless of communication language
- Translate technical concepts accurately
- Maintain professional technical writing standards
- Use objective, factual language without unnecessary embellishment
- Avoid competitive comparisons with other products/libraries
- Never use aggressive or dismissive language about alternatives
- Focus on functionality and benefits rather than superiority claims

### Chat Communication Style

When communicating with users in chat:
- Use professional, measured language
- Avoid excessive enthusiasm or superlatives
- Be helpful without being overly effusive
- Focus on accuracy and usefulness rather than excitement
- Acknowledge completion without dramatic celebration

## Examples by Context

### Commit Messages
```bash
# ✅ Always English
git commit -m ":zap: Optimize database query performance

Reduce N+1 queries by implementing eager loading.
- 5x performance improvement
- Maintains data consistency

:robot: Generated with [Agent Name](http://agent.url)
Co-Authored-By: Agent Name <agent@email>"
```

**Note**: Replace `[Agent Name]`, `http://agent.url`, and `<agent@email>` with your specific AI agent information.

### Code Reviews
```
# ✅ English preferred for broader team understanding
"This implementation could benefit from memoization to avoid 
recalculating expensive operations."

# ✅ Acceptable if team is primarily Japanese
"このメソッドは重い計算を繰り返しているので、メモ化を検討してください。"
```

### Chat Interactions
```
User: "テストが失敗しているようです"
AI: "テストの失敗を確認します。エラーログを見てみましょう。"

# When writing test code:
describe "performance optimization" do
  it "reduces query time by 50%" do
    # Test implementation in English
  end
end
```

## Documentation Style Guidelines

### Avoid Excessive Language

```markdown
❌ Overly dramatic
"This amazing, revolutionary feature completely transforms your workflow!"

✅ Factual and clear  
"This feature streamlines the authentication process by caching validated tokens."

❌ Unnecessary superlatives
"The world's most powerful, incredibly fast, absolutely best terminal styling library"

✅ Descriptive without embellishment
"A terminal styling library with performance optimization and composable style objects"
```

### Avoid Competitive Comparisons

```markdown
❌ Direct competition attacks
"Unlike slow Library X, our solution is blazing fast"
"Library Y is outdated and problematic, use this instead"

✅ Focus on own features
"Optimized for performance with 7-18x speed improvements"
"Designed with modern Ruby practices and immutable objects"

❌ Dismissive language
"Other libraries fail to provide..."
"The broken approach used by..."

✅ Neutral positioning
"This library provides..."
"Alternative approach that..."
```

### Maintain Professional Tone

```markdown
❌ Aggressive language
"Destroys performance bottlenecks"
"Kills the competition"
"Obliterates technical debt"

✅ Professional descriptions
"Addresses performance bottlenecks"
"Provides competitive performance"
"Reduces technical debt"

❌ Emotional appeals
"You'll absolutely love this feature!"
"Frustrating bugs are now history!"

✅ Factual benefits
"This feature improves developer experience"
"Resolves common integration issues"
```

### Chat Communication Examples

```
❌ Overly enthusiastic
"Perfect! Amazing! That's absolutely fantastic!"
"This is going to be incredible!"
"Wow, that's the best solution ever!"

✅ Professional acknowledgment  
"Completed. The changes have been applied."
"Good point. I've implemented that approach."
"That's been resolved. The tests are now passing."

❌ Excessive superlatives
"This incredibly powerful feature will revolutionize your workflow!"
"The absolutely perfect solution for your needs!"

✅ Measured descriptions
"This feature should improve your workflow efficiency."
"This approach addresses the requirements you mentioned."

❌ Dramatic language
"I'll completely transform this code!"
"Let me totally rebuild this system!"

✅ Factual descriptions
"I'll refactor this code to improve maintainability."
"Let me restructure this for better organization."
```

## Common Mistakes to Avoid

### Mixed Language Code
```ruby
# ❌ Never mix languages in code
def calculate_速度(distance, 時間)
  return distance / 時間
end

# ✅ Always use English
def calculate_speed(distance, time)
  return distance / time  
end
```

### Inconsistent Documentation Language
```ruby
# ❌ Inconsistent
# ユーザーのスコアを計算する
# @param user [User] The user object
def calculate_user_score(user)

# ✅ Consistent English
# Calculates the user's performance score
# @param user [User] The user object  
def calculate_user_score(user)
```

### Poor Translation of Technical Terms
```
# ❌ Direct translation loses meaning
"I will implement the 'hand procedure' for error handling"

# ✅ Keep technical terms or provide context
"I will implement exception handling (例外処理) for error cases"
```

This language guideline ensures clear, professional, and accessible code while maintaining effective communication with users in their preferred language.