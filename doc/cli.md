# CLI Reference

Foxtail provides command-line tools for working with FTL files.

## Commands

| Command | Description |
|---------|-------------|
| `foxtail ids` | Extract message and term IDs from FTL files |
| `foxtail lint` | Check FTL files for syntax errors |
| `foxtail parse` | Parse FTL files and output AST as JSON |
| `foxtail tidy` | Format FTL files with consistent style |

## lint

Check FTL files for syntax errors.

```bash
foxtail lint FILES
```

### Options

| Option | Alias | Description |
|--------|-------|-------------|
| `--quiet` | `-q` | Only show errors, no summary |

### Examples

```bash
# Check a single file
foxtail lint messages.ftl

# Check multiple files
foxtail lint en.ftl ja.ftl

# Quiet mode (only errors)
foxtail lint -q messages.ftl
```

## parse

Parse FTL files and output the AST as JSON.

```bash
foxtail parse FILES
```

### Options

| Option | Description |
|--------|-------------|
| `--with-spans` | Include source position information in output |

### Examples

```bash
# Parse a single file
foxtail parse messages.ftl

# Parse with span information
foxtail parse messages.ftl --with-spans

# Parse multiple files (outputs JSON array)
foxtail parse en.ftl ja.ftl

# Compare AST before and after tidy
foxtail parse original.ftl > before.json
foxtail tidy original.ftl > tidied.ftl
foxtail parse tidied.ftl > after.json
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
