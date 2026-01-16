# Foxtail Tools Examples

Executable examples demonstrating Foxtail Tools features.

## Running Examples

```bash
bundle exec ruby examples/01_prefix_message_ids.rb
```

## Examples

| File | Feature | Description |
|------|---------|-------------|
| [01_prefix_message_ids.rb](01_prefix_message_ids.rb) | AST transform | Prefix message IDs and update references |
| [02_german_nouns_from_csv.rb](02_german_nouns_from_csv.rb) | AST generation | Generate German noun terms from CSV data |

## Expected Output

Each example has an accompanying expected output file for verification:

```bash
bundle exec ruby examples/01_prefix_message_ids.rb | diff - examples/01_prefix_message_ids.expected.txt
```
