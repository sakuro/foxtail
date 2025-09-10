# Git Commit and Pull Request Guidelines for AI Agents

This guide helps AI agents follow the project's Git and GitHub conventions for commits, pull requests, and merges.

## Table of Contents
- [Commit Messages](#commit-messages)
- [Branch Management](#branch-management)
- [Pull Request Creation](#pull-request-creation)
- [Pull Request Merging](#pull-request-merging)
- [Common Issues and Solutions](#common-issues-and-solutions)

## Commit Messages

### Format Requirements

All commit messages MUST follow this format:

```
:emoji: Subject line in imperative mood

Detailed explanation of changes (optional)
- Bullet points for key changes
- Technical details and trade-offs

:robot: Generated with [Agent Name](http://agent.url)

Co-Authored-By: Agent Name <agent@email>
```

**Note**: Replace `[Agent Name]`, `http://agent.url`, and `<agent@email>` with your specific AI agent information.

### Key Rules

1. **Always use GitHub emoji codes** (`:emoji:`), never raw Unicode emojis
2. **Start with emoji**: The first character must be `:`
3. **Space after emoji**: `:emoji: Subject` not `:emoji:Subject`
4. **Imperative mood**: "Fix bug" not "Fixed bug" or "Fixes bug"
5. **No period at end of subject**
6. **Include AI attribution** for AI-generated commits

### Common Emoji Codes

| Emoji | Code | Use Case |
|-------|------|----------|
| ⚡ | `:zap:` | Performance improvements |
| 🐛 | `:bug:` | Bug fixes |
| ✨ | `:sparkles:` | New features |
| 📝 | `:memo:` | Documentation |
| ♻️ | `:recycle:` | Refactoring |
| 🎨 | `:art:` | Code structure/format improvements |
| 🔧 | `:wrench:` | Configuration changes |
| ✅ | `:white_check_mark:` | Adding/updating tests |
| 🔥 | `:fire:` | Removing code/files |
| 📦 | `:package:` | Updating dependencies |

### Commit Command Example

```bash
git commit -m "$(cat <<'EOF'
:zap: Optimize Style#call performance with caching

Cache SGR sequences at initialization to avoid recalculation.
- 7-18x performance improvement
- 85-91% reduction in object allocations

:robot: Generated with [Agent Name](http://agent.url)

Co-Authored-By: Agent Name <agent@email>
EOF
)"
```

**Important**: Use heredoc with single quotes (`<<'EOF'`) to preserve special characters.

## Branch Management

### Branch Naming Convention

```
type/description-with-hyphens
```

Examples:
- `feature/style-performance-optimization`
- `fix/readme-installation-instructions`
- `docs/git-pr-guidelines`
- `cleanup/remove-described-class`

### Creating a New Branch

```bash
git switch -c feature/your-feature-name
```

## Pull Request Creation

### Using gh CLI

Always use the `gh` CLI tool for creating pull requests.

### Basic PR Creation

```bash
gh pr create --title ":emoji: Clear descriptive title" --body "PR description"
```

### PR with Complex Body

For PR bodies containing backticks or complex markdown, use command substitution with heredoc:

```bash
gh pr create --title ":memo: Update documentation" --body "$(cat <<'EOF'
## Summary
Brief description of changes

## Changes
- Change 1
- Change 2

## Before
```ruby
old_code
```

## After
```ruby
new_code
```

:robot: Generated with [Agent Name](http://agent.url)
EOF
)"
```

### PR Title Format

- Must start with GitHub emoji code (same as commits)
- Clear, descriptive title
- Example: `:zap: Optimize Style#call performance with SGR caching`

## Pull Request Merging

### Merge Command Format

Use merge commits (not squash) with custom messages:

```bash
gh pr merge PR_NUMBER --merge \
  --subject ":inbox_tray: :emoji: Merge pull request #PR from branch" \
  --body "Brief description of what was merged"
```

### Merge Commit Convention

The merge commit automatically gets `:inbox_tray:` prefix, so the format is:

```
:inbox_tray: :original_emoji: Merge pull request #N from user/branch
```

Example:
```bash
gh pr merge 6 --merge \
  --subject ":inbox_tray: :zap: Merge pull request #6 from sakuro/feature/style-performance-optimization" \
  --body "Style#call performance optimization with SGR caching"
```

## Common Issues and Solutions

### Issue: Commit Hook Rejects Message

**Error**: "Commit message must start with a GitHub :emoji:"

**Solution**: Ensure your commit message starts with `:emoji_code:` (colon on both sides)

### Issue: Raw Emoji in Commit

**Error**: "Commit message contains raw emojis"

**Solution**: Replace Unicode emoji (🎉) with GitHub codes (`:tada:`)

### Issue: Backticks in PR Body

**Problem**: Backticks in heredoc cause shell interpretation issues

**Solution**: Use command substitution with heredoc:
```bash
gh pr create --title "Title" --body "$(cat <<'EOF'
Content with `backticks` in markdown
EOF
)"
```

### Issue: Pre-push Hook Failures

**Problem**: RuboCop or tests fail during push

**Solution**:
1. Run `rake` locally first
2. Fix any issues before pushing
3. Use `bundle exec rubocop -A` for safe auto-fixes

## Staging Changes Safely

### Avoid Bulk Operations

**Never use these commands** as they can add unintended files:
```bash
git add .        # Adds ALL files in current directory
git add -A       # Adds ALL tracked and untracked files
git add *        # Adds files matching shell glob
```

### Recommended Approaches

**Option 1: Add specific files explicitly**
```bash
git add lib/specific_file.rb
git add spec/specific_spec.rb
git add README.md
```

**Option 2: Review changes first, then stage**
```bash
# See what would be added
git status
git diff

# Add specific files you want to commit
git add path/to/changed_file.rb
```

**Option 3: Interactive staging for complex changes**
```bash
git add -p    # Review and stage changes interactively
```

## Best Practices

1. **Always run tests before pushing**: `rake` or `bundle exec rspec`
2. **Check RuboCop**: `bundle exec rubocop` before committing
3. **Keep commits focused**: One logical change per commit
4. **Stage files explicitly**: Avoid `git add .` - specify files individually
5. **Review staged changes**: Use `git diff --cached` before committing
6. **Write clear PR descriptions**: Include before/after examples when relevant
7. **Link issues**: Use "Fixes #123" in PR descriptions
8. **Update documentation**: Keep README and CHANGELOG current

## Example Workflow

```bash
# 1. Create branch
git switch -c fix/performance-issue

# 2. Make changes
# ... edit files ...

# 3. Run tests and lint
rake

# 4. Stage changes (be specific!)
git add lib/performance_fix.rb
git add spec/performance_fix_spec.rb

# 5. Commit with proper message
git commit -m "$(cat <<'EOF'
:zap: Fix performance regression in render method

Memoize expensive calculations to avoid recalculation.
- 3x faster rendering
- Reduces memory allocations

Fixes #42

:robot: Generated with [Agent Name](http://agent.url)

Co-Authored-By: Agent Name <agent@email>
EOF
)"

# 6. Push branch
git push -u origin fix/performance-issue

# 7. Create PR
gh pr create --title ":zap: Fix performance regression in render method" \
  --body "Fixes #42 - Memoization of expensive calculations"

# 8. After approval, merge
gh pr merge 7 --merge \
  --subject ":inbox_tray: :zap: Merge pull request #7 from sakuro/fix/performance-issue" \
  --body "Performance fix through memoization"
```

## References

- [GitHub Emoji Codes](https://github.com/ikatyang/emoji-cheat-sheet)
- [Conventional Commits](https://www.conventionalcommits.org/)
- Project's commit hooks in `.git/hooks/`
