# CLDR Test Fixtures

This directory contains CLDR (Common Locale Data Repository) test fixture files used across multiple test suites.

## Directory Structure

```
spec/fixtures/cldr/
├── README.md                          # This file
├── en/
│   └── number_formats.yml             # English locale number formats
├── en_001/
│   └── number_formats.yml             # English (World) locale number formats
├── ja/
│   ├── datetime_formats.yml           # Japanese locale datetime formats
│   └── number_formats.yml             # Japanese locale number formats
├── ja_JP/
│   └── number_formats.yml             # Japanese (Japan) locale number formats
├── root/
│   ├── datetime_formats.yml           # Root locale datetime formats
│   ├── number_formats.yml             # Root locale number formats
│   └── plural_rules.yml               # Root locale plural rules
├── malformed_parent_locales.yml       # Intentionally malformed YAML for error testing
├── parent_locales.yml                 # Standard parent locale mappings
├── test_parent_locales.yml            # Test-specific parent locale mappings
└── valid_parent_locales.yml           # Valid parent locale mappings
```

## File Usage

### Locale-Specific Data Files

| File | Format | Used By | Purpose |
|------|--------|---------|---------|
| `en/number_formats.yml` | Locale data | `resolver_spec.rb` | English number formatting data for inheritance testing |
| `en_001/number_formats.yml` | Locale data | `resolver_spec.rb` | English (World) currency symbols for parent locale testing |
| `ja/datetime_formats.yml` | Locale data | `resolver_spec.rb` | Japanese datetime formatting for datetime resolution testing |
| `ja/number_formats.yml` | Locale data | `resolver_spec.rb` | Japanese number formatting data for inheritance testing |
| `ja_JP/number_formats.yml` | Locale data | `resolver_spec.rb` | Japanese (Japan) currency data for locale resolution testing |
| `root/datetime_formats.yml` | Locale data | `resolver_spec.rb` | Root datetime formats for fallback testing |
| `root/number_formats.yml` | Locale data | `resolver_spec.rb` | Root number formatting data for fallback testing |
| `root/plural_rules.yml` | Locale data | `plural_rules_spec.rb` | Root plural rules for fallback testing |

### Configuration Files

| File | Format | Used By | Purpose |
|------|--------|---------|---------|
| `parent_locales.yml` | Config | General tests | Standard CLDR parent locale mappings |
| `test_parent_locales.yml` | Config | `resolver_spec.rb` | Test-specific parent locale mappings for inheritance chain testing |
| `valid_parent_locales.yml` | Config | `inheritance_spec.rb` | Valid parent locale mappings for positive testing |
| `malformed_parent_locales.yml` | Config | `inheritance_spec.rb` | Intentionally malformed YAML for error handling testing |

## Data Format

### Locale Data Files

All locale-specific YAML files follow this structure:

```yaml
locale: <locale_id>
generated_at: "2024-01-01T00:00:00Z"  # ISO8601 string format for Psych compatibility
cldr_version: '45.0'
<data_type>:
  # Locale-specific data structure
```

### Parent Locales Files

Parent locale mapping files follow this structure:

```yaml
parent_locales:
  <child_locale>: <parent_locale>
  # e.g., en_AU: en_001
```

## Test Coverage

### Repository Tests
- **`resolver_spec.rb`**: Tests locale data resolution and inheritance chains
  - Uses: All locale data files, `test_parent_locales.yml`
  - Coverage: Data resolution, inheritance, fallback behavior, parent locale chains

- **`inheritance_spec.rb`**: Tests inheritance logic and error handling
  - Uses: `valid_parent_locales.yml`, `malformed_parent_locales.yml`
  - Coverage: Parent locale loading, YAML parsing, error conditions

### Extractor Tests
- **`plural_rules_spec.rb`**: Tests plural rules extraction and fallback
  - Uses: `root/plural_rules.yml`
  - Coverage: Japanese locale fallback to root behavior

## Maintenance Notes

### When Adding New Fixtures
1. Follow the established naming convention: `<locale>/<data_type>.yml`
2. Ensure `generated_at` is quoted as a string for Psych compatibility
3. Update this README with the new file's purpose and usage
4. Consider inheritance chains when creating locale-specific data

### When Modifying Fixtures
1. Check all tests listed in "Used By" column before making changes
2. Maintain data consistency across inheritance chains
3. Preserve the YAML structure expected by the application code

### Error Testing
The `malformed_parent_locales.yml` file intentionally contains invalid YAML syntax to test error handling. Do not "fix" this file as it serves a specific testing purpose.

## Related Documentation
- [CLDR Specification](https://unicode.org/reports/tr35/)
- [Locale Inheritance Documentation](../../../docs/cldr-inheritance.md) (if exists)
- [Extractor Testing Guidelines](../../../docs/testing-extractors.md) (if exists)