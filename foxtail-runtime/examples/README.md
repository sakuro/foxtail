# Foxtail Examples

Executable examples demonstrating Foxtail features.

## Running Examples

```bash
# Simple examples
bundle exec ruby foxtail-runtime/examples/01_basic.rb

# Practical scenarios
bundle exec ruby foxtail-runtime/examples/multilingual_app/main.rb
```

## Simple Examples

| File | Feature | Description |
|------|---------|-------------|
| [01_basic.rb](01_basic.rb) | Basics | Messages, variables, Bundle creation |
| [02_selectors.rb](02_selectors.rb) | Selectors | Plurals, gender, numeric matching |
| [03_attributes_and_terms.rb](03_attributes_and_terms.rb) | Attributes & Terms | `.attribute` syntax, `-term` references |
| [04_number_format.rb](04_number_format.rb) | NUMBER | Currency, percent, digit formatting |
| [05_datetime_format.rb](05_datetime_format.rb) | DATETIME | Date/time formatting |
| [06_custom_functions.rb](06_custom_functions.rb) | Custom Functions | Custom formatter injection |
| [07_error_handling.rb](07_error_handling.rb) | Errors | Parse errors, missing variables |

## Practical Scenarios

| Directory | Scenario | Features |
|-----------|----------|----------|
| [multilingual_app/](multilingual_app/) | Multi-language app | Sequence, file loading, fallback |
| [ecommerce/](ecommerce/) | E-commerce pricing | NUMBER, plurals, attributes |
| [dungeon_game/](dungeon_game/) | Item localization | Gender, case, elision, counters |

## Expected Output Files

Each example has an accompanying expected output file for verification:

- Simple examples: `NN_name.expected.txt` (e.g., `01_basic.expected.txt`)
- Practical scenarios: `expected.txt` inside the directory

Compare actual output with expected:

```bash
bundle exec ruby foxtail-runtime/examples/01_basic.rb | diff - foxtail-runtime/examples/01_basic.expected.txt
```

## Prerequisites

Ensure `icu4x` is configured. Run `bin/setup` if needed.
