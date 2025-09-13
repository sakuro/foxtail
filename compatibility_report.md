# Fluent.js Compatibility Report

## Summary

| Metric | Count | Percentage |
|--------|------:|-----------:|
| Perfect matches | 97 | 99.0% |
| Partial matches | 0 | 0.0% |
| Content differences | 0 | 0.0% |
| Parsing failures | 0 | 0.0% |
| Known incompatibilities | 1 | 1.0% |

*Total fixtures: 98*


## Category Breakdown

| Category | Perfect | Functional | Total |
|----------|---------|------------|-------|
| 📐 Structure | 62 (100.0%) | 62 (100.0%) | 62 |
| 📚 Reference | 35 (97.2%) | 35 (97.2%) | 36 |


<details>
<summary>✅ Structure perfect matches (62)</summary>

- attribute_expression_with_wrong_attr
- attribute_of_private_as_placeable
- attribute_of_public_as_selector
- attribute_starts_from_nl
- attribute_with_empty_pattern
- attribute_without_equal_sign
- blank_lines
- broken_number
- call_expression_errors
- comment_with_eof
- crlf
- dash_at_eof
- elements_indent
- empty_resource
- empty_resource_with_ws
- escape_sequences
- expressions_call_args
- indent
- junk
- leading_dots
- leading_empty_lines
- leading_empty_lines_with_ws
- message_reference_as_selector
- message_with_empty_multiline_pattern
- message_with_empty_pattern
- multiline-comment
- multiline_pattern
- multiline_string
- multiline_with_non_empty_first_line
- multiline_with_placeables
- non_id_attribute_name
- placeable_at_eol
- placeable_at_line_extremes
- placeable_in_placeable
- placeable_without_close_bracket
- resource_comment
- resource_comment_trailing_line
- second_attribute_starts_from_nl
- select_expression_with_two_selectors
- select_expression_without_arrow
- select_expression_without_variants
- select_expressions
- simple_message
- single_char_id
- sparse-messages
- standalone_comment
- standalone_identifier
- term
- term_with_empty_pattern
- unclosed
- unclosed_empty_placeable_error
- unknown_entry_start
- variant_ends_abruptly
- variant_keys
- variant_starts_from_nl
- variant_with_digit_key
- variant_with_empty_pattern
- variant_with_leading_space_in_name
- variant_with_symbol_with_space
- variants_with_two_defaults
- whitespace_leading
- whitespace_trailing

</details>
<details>
<summary>✅ Reference perfect matches (35)</summary>

- any_char
- astral
- call_expressions
- callee_expressions
- comments
- cr
- crlf
- eof_comment
- eof_empty
- eof_id
- eof_id_equals
- eof_junk
- eof_value
- escaped_characters
- junk
- literal_expressions
- member_expressions
- messages
- mixed_entries
- multiline_values
- numbers
- obsolete
- placeables
- reference_expressions
- select_expressions
- select_indent
- sparse_entries
- special_chars
- tab
- term_parameters
- terms
- variables
- variant_keys
- whitespace_in_value
- zero_length

</details>
### 🚧 Known incompatibilities (1)

> These are intentional differences from fluent.js behavior

- **reference**: leading_dots

