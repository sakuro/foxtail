# CLI Reference

Fantail provides command-line tools for working with FTL files.

## Commands

| Command | Description |
|---------|-------------|
| `fantail check` | Check FTL files for syntax errors |
| `fantail dump` | Dump FTL files as AST in JSON format |
| `fantail ids` | Extract message and term IDs from FTL files |
| `fantail tidy` | Format FTL files with consistent style |

## check

Check FTL files for syntax errors.

```bash
fantail check FILES
```

### Options

| Option | Alias | Description |
|--------|-------|-------------|
| `--quiet` | `-q` | Only show errors, no summary |

### Examples

```bash
# Check a single file
fantail check messages.ftl

# Check multiple files
fantail check en.ftl ja.ftl

# Quiet mode (only errors)
fantail check -q messages.ftl
```

## dump

Dump FTL files as AST in JSON format.

```bash
fantail dump FILES
```

### Options

| Option | Description |
|--------|-------------|
| `--with-spans` | Include source position information in output |

### Examples

```bash
# Dump a single file
fantail dump messages.ftl

# Dump with span information
fantail dump messages.ftl --with-spans

# Dump multiple files (outputs JSON array)
fantail dump en.ftl ja.ftl

# Compare AST before and after tidy
fantail dump original.ftl > before.json
fantail tidy original.ftl > tidied.ftl
fantail dump tidied.ftl > after.json
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
fantail tidy FILES
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
fantail tidy messages.ftl

# Format in place
fantail tidy -w messages.ftl

# Check formatting (for CI)
fantail tidy -c messages.ftl

# Show diff
fantail tidy -d messages.ftl
```

## ids

Extract message and term IDs from FTL files.

```bash
fantail ids FILES
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
fantail ids messages.ftl

# Only message IDs
fantail ids -m messages.ftl

# Only term IDs
fantail ids -t messages.ftl

# Include attributes
fantail ids -a messages.ftl
# Output: greeting, greeting.placeholder, -brand, -brand.short

# JSON output
fantail ids -j messages.ftl
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
