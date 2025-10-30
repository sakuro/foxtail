# Git Commit and Pull Request Guidelines for AI Agents

This guide helps AI agents follow the project's Git and GitHub conventions for commits, pull requests, and merges.

## Table of Contents
- [Commit Messages](#commit-messages)
- [Branch Management](#branch-management)
- [Pull Request Creation](#pull-request-creation)
- [Pull Request Merging](#pull-request-merging)
- [Common Issues and Solutions](#common-issues-and-solutions)

## Commit Messages

> **Note**: For detailed commit workflow including pre-commit checks, file staging,
> and message formatting, see the `git-commit` skill at `.claude/skills/git-commit/SKILL.md`.

### Format Requirements

```
:emoji: Subject line in imperative mood

Brief explanation (optional, keep concise)

:robot: Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

### Key Rules

1. Start with GitHub emoji code (`:emoji:`), never raw Unicode emojis
2. Use imperative mood: "Fix bug" not "Fixed bug"
3. Keep messages concise: focus on what/why, not how
4. Always use heredoc for multi-line commits: `git commit -m "$(cat <<'EOF' ... EOF)"`

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

> **Note**: For detailed PR creation workflow including body formatting, shell safety,
> and complete examples, see the `create-pr` skill at `.claude/skills/create-pr/SKILL.md`.

### Key Requirements

1. **Use gh CLI**: Always use `gh pr create` command
2. **Title format**: Start with emoji code, use English, imperative mood
3. **Body method**: Use temp file (`--body-file`) or quoted heredoc (`<<'EOF'`)
4. **Never use**: Inline `--body` with complex content or unquoted heredoc

### Basic Structure

```bash
cat > /tmp/pr_body.md <<'EOF'
## Summary
Brief description

## Changes
- Key change 1
- Key change 2

:robot: Generated with [Claude Code](https://claude.com/claude-code)
EOF

gh pr create --title ":emoji: Descriptive title" --body-file /tmp/pr_body.md
rm /tmp/pr_body.md
```

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

**Solution**: Use temp file or quoted heredoc (`<<'EOF'`). See `create-pr` skill for details.

### Issue: Pre-push Hook Failures

**Problem**: Tests or linters fail during push

**Solution**: Run tests and linters locally first (see `git-commit` skill for details)

## Staging Changes Safely

> **Note**: For detailed staging workflow, see the `git-commit` skill.

**CRITICAL: Never use bulk operations:**
```bash
git add .        # ❌ Adds ALL files
git add -A       # ❌ Adds ALL tracked and untracked files
git add *        # ❌ Adds files matching shell glob
```

**Always add specific files explicitly:**
```bash
git add README.md
git add lib/module/file.ext
```

## Best Practices

**For commits** (see `git-commit` skill for details):
1. Always run tests before committing
2. Stage files explicitly - never use `git add .`
3. Keep commits focused - one logical change per commit
4. Write concise commit messages

**For pull requests:**
1. **Write clear PR descriptions**: Include before/after examples when relevant
2. **Link issues**: Use "Fixes #123" in PR descriptions
3. **Update documentation**: Keep README and CHANGELOG current

## Example Workflow

```bash
# 1. Create branch
git switch -c fix/performance-issue

# 2. Make changes
# ... edit files ...

# 3-5. Commit changes (see git-commit skill for details)
# - Run tests
# - Stage specific files
# - Commit with proper message format

# 6. Push branch
git push -u origin fix/performance-issue

# 7. Create PR (see create-pr skill for details)
gh pr create --title ":zap: Fix performance regression in render method" \
  --body-file /tmp/pr_body.md

# 8. After approval, merge
gh pr merge 7 --merge \
  --subject ":inbox_tray: :zap: Merge pull request #7 from sakuro/fix/performance-issue" \
  --body "Performance fix through memoization"
```

## References

- [GitHub Emoji Codes](https://github.com/ikatyang/emoji-cheat-sheet)
- [Conventional Commits](https://www.conventionalcommits.org/)
- Project's commit hooks in `.git/hooks/`
