# CLI Reference

Foxtail provides command-line tools for working with FTL files.

## Gem and Entry Point

The CLI is provided by the `foxtail-tools` gem.

```ruby
require "foxtail-tools"   # CLI and tooling APIs
```

## Commands

| Command | Description |
|---------|-------------|
| `foxtail check` | Check FTL files for syntax errors |
| `foxtail dump` | Dump FTL files as AST in JSON format |
| `foxtail ids` | Extract message and term IDs from FTL files |
| `foxtail tidy` | Format FTL files with consistent style |

## check

Check FTL files for syntax errors.

```bash
foxtail check FILES
```

### Options

| Option | Alias | Description |
|--------|-------|-------------|
| `--quiet` | `-q` | Only show errors, no summary |

### Examples

```bash
# Check a single file
foxtail check messages.ftl

# Check multiple files
foxtail check en.ftl ja.ftl

# Quiet mode (only errors)
foxtail check -q messages.ftl
```

## dump

Dump FTL files as AST in JSON format.

```bash
foxtail dump FILES
```

### Options

| Option | Description |
|--------|-------------|
| `--with-spans` | Include source position information in output |

### Examples

```bash
# Dump a single file
foxtail dump messages.ftl

# Dump with span information
foxtail dump messages.ftl --with-spans

# Dump multiple files (outputs JSON array)
foxtail dump en.ftl ja.ftl

# Compare AST before and after tidy
foxtail dump original.ftl > before.json
foxtail tidy original.ftl > tidied.ftl
foxtail dump tidied.ftl > after.json
diff before.json after.json
```

### Output Format

JSON output follows the fluent.js AST structure:

```json
{
  "file": "messages.ftl",
  "ast": {
    "type": "Resource",
    "body": [
      {
        "type": "Message",
        "id": { "type": "Identifier", "name": "hello" },
        "value": { "type": "Pattern", "elements": [...] },
        "attributes": [],
        "comment": null
      }
    ]
  }
}
```

## tidy

Format FTL files with consistent style.

```bash
foxtail tidy FILES
```

### Options

| Option | Alias | Description |
|--------|-------|-------------|
| `--write` | `-w` | Write result back to source file |
| `--check` | `-c` | Check if files are formatted (for CI) |
| `--diff` | `-d` | Show diff instead of formatted output |
| `--with-junk` | | Allow formatting files with syntax errors |

### Examples

```bash
# Preview formatted output
foxtail tidy messages.ftl

# Format in place
foxtail tidy -w messages.ftl

# Check formatting (for CI)
foxtail tidy -c messages.ftl

# Show diff
foxtail tidy -d messages.ftl
```

## ids

Extract message and term IDs from FTL files.

```bash
foxtail ids FILES
```

### Options

| Option | Alias | Description |
|--------|-------|-------------|
| `--only-messages` | `-m` | Show only message IDs |
| `--only-terms` | `-t` | Show only term IDs |
| `--with-attributes` | `-a` | Include attribute names |
| `--json` | `-j` | Output as JSON array |

### Examples

```bash
# List all IDs
foxtail ids messages.ftl

# Only message IDs
foxtail ids -m messages.ftl

# Only term IDs
foxtail ids -t messages.ftl

# Include attributes
foxtail ids -a messages.ftl
# Output: greeting, greeting.placeholder, -brand, -brand.short

# JSON output
foxtail ids -j messages.ftl
# Output: ["greeting", "-brand"]
```

### Output Format

By default, IDs are output one per line:

```
greeting
-brand
```

With `--json`, output is a JSON array:

```json
[
  "greeting",
  "-brand"
]
```
