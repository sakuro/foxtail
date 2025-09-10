# RuboCop Fix Workflow for AI Agents

This guide outlines a safe, repeatable process to fix RuboCop offenses while preserving behavior and keeping PRs focused.

## Goals
- Keep changes minimal and behavior‑preserving; prefer small, focused PRs.
- Use safe autocorrect first; apply unsafe corrections only when reviewed and covered by tests.
- Centralize rule changes in `.rubocop.yml`; never hand‑edit `.rubocop_todo.yml`.

## Quick Commands
- Full lint: `rake rubocop`
- File/dir lint: `rubocop path/to/file.rb`
- Safe autocorrect: `rubocop -a`
- Targeted unsafe: `rubocop -A --only Cop/Name`
- Run tests: `rake spec`
- Regenerate TODO: `docquet regenerate-todo`
 - Temporarily enable a TODO‑disabled cop: comment out its block in `.rubocop_todo.yml`

## Workflow
1) Reproduce locally
- Run `rake rubocop` and note failing cops/files.

2) Safe autocorrect first
- Run `rubocop -a` on specific files or directories to reduce blast radius.
- Re‑run `rake rubocop` and `rake spec` to verify no behavior changes.

3) Target specific cops (if still failing)
- For stylistic issues, fix manually or run `rubocop -A --only Cop/Name` on the smallest scope.
- For logic‑sensitive cops (e.g., Performance, Lint), prefer manual fixes with tests.

3a) If the cop is disabled in `.rubocop_todo.yml`
- Open `.rubocop_todo.yml`, locate the `Cop/Name` entry, and temporarily comment out (or remove locally) that entire block. RuboCop respects TODO disables even with `--only`, so this is required to surface offenses.
- Run `rubocop --only Cop/Name` (optionally `-A`) on a narrow path and fix findings.
- Validate with `rake rubocop` and `rake spec`.
- Refresh the TODO: run `docquet regenerate-todo` to update/remove the entry based on remaining offenses. Commit code changes and the regenerated `.rubocop_todo.yml` together in the same commit/PR.

4) Update configuration (rare)
- If a rule conflicts with project style, adjust `.rubocop.yml` with rationale in the PR body.
- Do not edit `.rubocop_todo.yml` manually. After large cleanups, run `docquet regenerate-todo` and commit only that file.

5) No inline disables
- Do not use comment-based disables (`# rubocop:disable ...`). This project forbids inline disables.
- If a finding cannot be safely fixed, pause and ask the maintainer for guidance. Options may include refining the rule in `.rubocop.yml` or adjusting the approach.

6) Validate and commit
- Ensure `rake` (tests + lint) is green.
- Commit messages must start with a GitHub `:emoji:` and use imperative mood.
  Examples:
  - `:lipstick: RuboCop: safe autocorrect in lib/fasti/cli.rb`
  - `:rotating_light: RuboCop: fix Lint/UnusedMethodArgument`

## PR Guidance
- Keep changes small and single‑purpose (e.g., "fix Style/StringLiterals in lib/fasti").
- Include before/after snippets if unsafe autocorrect or refactor was applied.
- Link any rule changes to rationale and project conventions.
