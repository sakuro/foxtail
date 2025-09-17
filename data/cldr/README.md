# CLDR Localization Data

This directory contains localization data extracted from Unicode CLDR (Common Locale Data Repository).

## Data Files

### Per-Locale Data
- `{locale}/plural_rules.yml` - Plural rules for each locale with distinct rules
- `{locale}/number_formats.yml` - Number and percent formatting patterns
- `{locale}/currencies.yml` - Currency names and symbols
- `{locale}/datetime_formats.yml` - Date/time formatting patterns including months, weekdays
- `{locale}/timezone_names.yml` - Timezone display names
- `{locale}/units.yml` - Unit formatting patterns for measurements

### Global Configuration Files
- `parent_locales.yml` - Parent locale mappings for inheritance chains
- `locale_aliases.yml` - Locale aliases and canonical locale mappings
- `metazone_mapping.yml` - Metazone mappings for timezone formatting

## Directory Structure

```
data/cldr/
├── README.md                    # This file
├── locale_aliases.yml           # Global locale alias mappings
├── parent_locales.yml           # Parent locale inheritance mappings
├── metazone_mapping.yml         # Timezone metazone mappings
├── {locale}/                    # Per-locale data directories
│   ├── plural_rules.yml         # Plural rule conditions (if different from root)
│   ├── number_formats.yml       # Number and percent formatting patterns
│   ├── currencies.yml           # Currency names and symbols
│   ├── datetime_formats.yml     # Date/time patterns and names
│   ├── timezone_names.yml       # Timezone display names
│   └── units.yml                # Unit formatting patterns
└── root/                        # Root locale (fallback data)
    ├── plural_rules.yml         # Default plural rules
    └── ...                      # Other root locale data
```

## Data Extraction

Available Rake tasks for CLDR data management:

```bash
# Extract all CLDR data types
bundle exec rake cldr:extract

# Extract specific data types
bundle exec rake cldr:extract:parent_locales
bundle exec rake cldr:extract:locale_aliases
bundle exec rake cldr:extract:plural_rules
bundle exec rake cldr:extract:number_formats
bundle exec rake cldr:extract:currencies
bundle exec rake cldr:extract:datetime_formats
bundle exec rake cldr:extract:timezone_names
bundle exec rake cldr:extract:units
bundle exec rake cldr:extract:metazone_mapping

# Extract data for specific locale
bundle exec rake cldr:extract:locale[ja]
```

## Usage

Data is automatically loaded by CLDR repository classes:

```ruby
# Plural rules
locale = Locale::Tag.parse("en")
plural_rules = Foxtail::CLDR::Repository::PluralRules.new(locale)
plural_rules.select(1)    # => "one"
plural_rules.select(2)    # => "other"

# Currency data
locale = Locale::Tag.parse("ja")
currencies = Foxtail::CLDR::Repository::Currencies.new(locale)
# Refer to actual implementation for available methods

# Units data
locale = Locale::Tag.parse("en")
units = Foxtail::CLDR::Repository::Units.new(locale)
# Refer to actual implementation for available methods

# Timezone names
locale = Locale::Tag.parse("ja")
timezone_names = Foxtail::CLDR::Repository::TimezoneNames.new(locale)
# Refer to actual implementation for available methods
```

## Data Format

All YAML files follow a consistent structure:

```yaml
locale: <locale_id>               # Locale identifier (e.g., "en", "ja_JP")
generated_at: "2024-01-01T00:00:00Z"  # Generation timestamp (ISO8601 string)
cldr_version: "46"                # CLDR source version
<data_type>:                      # Data content varies by file type
  # Locale-specific data structure
```

## Inheritance and Fallback

The CLDR system uses a sophisticated inheritance model:

1. **Locale Chain**: `ja_JP` → `ja` → `root`
2. **Parent Locales**: Custom inheritance (e.g., `en_AU` → `en_001` → `en` → `root`)
3. **Data Merging**: Child data overrides parent data at the field level

### Japanese Plural Rules Example
Japanese uses only the "other" plural form, so it falls back to root locale instead of creating a separate file.

## Data Source

- **Source**: Unicode CLDR v46
- **License**: Unicode License v3
- **URL**: https://unicode.org/cldr/

## Maintenance

### Adding New Locales
1. Run `bundle exec rake cldr:extract:locale[<locale>]`
2. Verify inheritance chain works correctly
3. Check that only necessary data is stored (avoid duplication with parent locales)

### Updating CLDR Version
1. Update `Foxtail::CLDR::SOURCE_VERSION` in `lib/foxtail/cldr.rb`
2. Run full extraction: `bundle exec rake cldr:extract`
3. Review changes and test inheritance behavior
4. Verify that new version data is correctly extracted

## File Storage

### Version-specific Download Files
Downloaded CLDR files are stored with version numbers added to their filenames for better management:
- Original: `cldr-core.zip` → Local: `tmp/cldr-core-v46.zip`
- Extracted directory: `tmp/cldr-core-v46/`

This approach:
- Allows keeping multiple CLDR versions for testing
- Makes version switching easier
- Eliminates the need to manually delete files when updating versions

## Related Documentation
- [Unicode CLDR Specification](https://unicode.org/reports/tr35/)
- [CLDR Inheritance Rules](https://unicode.org/reports/tr35/#Locale_Inheritance)
