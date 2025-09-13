# CLDR Localization Data

This directory contains localization data extracted from Unicode CLDR (Common Locale Data Repository).

## Data Files

- `{locale}/plural_rules.yml` - Plural rules for individual locales
- `{locale}/number_formats.yml` - Number, currency, and percent formatting data
- `{locale}/datetime_formats.yml` - Date/time formatting data
- `parent_locales.yml` - Parent locale mappings for inheritance
- `locale_aliases.yml` - Locale aliases and likely subtags

## Data Extraction

Available rake tasks for CLDR data management:

```bash
# Extract all CLDR data types
bundle exec rake cldr:extract

# Extract specific data types
bundle exec rake cldr:extract:parent_locales
bundle exec rake cldr:extract:plural_rules
bundle exec rake cldr:extract:number_formats
bundle exec rake cldr:extract:datetime_formats

# Extract data for specific locale
bundle exec rake cldr:extract:locale[ja]
```

## Usage

Data is automatically loaded by CLDR repository classes:

```ruby
# Plural rules
plural_rules = Foxtail::CLDR::Repository::PluralRules.new(Locale::Tag.parse("en"))
plural_rules.select(1)  # => :one
plural_rules.select(2)  # => :other

# Number formatting
number_formats = Foxtail::CLDR::Repository::NumberFormats.new(Locale::Tag.parse("en"))
number_formats.currency_symbol("USD")  # => "US$"
number_formats.currency_names("USD")   # => {:other=>"US dollars", :one=>"US dollar"}

# Date/time formatting
datetime_formats = Foxtail::CLDR::Repository::DateTimeFormats.new(Locale::Tag.parse("ja"))
datetime_formats.month_name(6, :wide)      # => "6月"
datetime_formats.weekday_name(:thu, :wide) # => "木曜日"
```

## Data Source

- **Source**: Unicode CLDR v46
- **License**: Unicode License v3
