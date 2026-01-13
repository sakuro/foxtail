# ICU4X Integration

## Overview

Foxtail uses the `icu4x` gem (Ruby bindings for [ICU4X](https://github.com/unicode-org/icu4x)) for locale-aware formatting. ICU4X is a Unicode Consortium project providing modern internationalization support.

## Setup

### Dependencies

The `icu4x` gem requires data files for locale-specific rules.

```ruby
# Gemfile
gem "icu4x"
gem "icu4x-data-recommended" # Provides data files
```

### Configuration

Set the `ICU4X_DATA_PATH` environment variable:

```bash
# In .env or shell configuration
export ICU4X_DATA_PATH=/path/to/icu4x-data
```

The `bin/setup` script automatically configures this for development.

## Components Used

### ICU4X::Locale

Used for locale parsing and management:

```ruby
locale = ICU4X::Locale.parse("en-US")
locale = ICU4X::Locale.parse("ja-JP")
locale = ICU4X::Locale.parse("de-DE")
```

### ICU4X::NumberFormat

Provides number formatting with various styles:

```ruby
formatter = ICU4X::NumberFormat.new(locale, style: :decimal)
formatter.format(1234.56)  # "1,234.56" (en-US)

formatter = ICU4X::NumberFormat.new(locale, style: :currency, currency: "USD")
formatter.format(99.99)    # "$99.99" (en-US)

formatter = ICU4X::NumberFormat.new(locale, style: :percent)
formatter.format(0.15)     # "15%" (en-US)
```

### ICU4X::DateTimeFormat

Provides date/time formatting:

```ruby
formatter = ICU4X::DateTimeFormat.new(locale, date_style: :long)
formatter.format(Time.now)  # "January 4, 2026" (en-US)

formatter = ICU4X::DateTimeFormat.new(locale, time_style: :short)
formatter.format(Time.now)  # "2:30 PM" (en-US)
```

### ICU4X::PluralRules

Determines plural categories for locale-aware pluralization:

```ruby
rules = ICU4X::PluralRules.new(locale)
rules.select(0)   # => :other (English)
rules.select(1)   # => :one
rules.select(2)   # => :other
rules.select(5)   # => :other

# Japanese: no plural distinction
ja_rules = ICU4X::PluralRules.new(ICU4X::Locale.parse("ja"))
ja_rules.select(1)   # => :other
ja_rules.select(100) # => :other
```

## Built-in Functions

### NUMBER

Formats numbers with locale-aware formatting.

**FTL Syntax**:

```ftl
count = { NUMBER($value) }
price = { NUMBER($amount, style: "currency", currency: "USD") }
ratio = { NUMBER($percent, style: "percent") }
```

**Options** (FTL → ICU4X mapping):

| FTL Option (camelCase) | ICU4X Option | Description |
|------------------------|--------------|-------------|
| `style` | `style` | `:decimal`, `:currency`, `:percent`, `:scientific` |
| `currency` | `currency` | Currency code (e.g., "USD", "JPY") |
| `minimumIntegerDigits` | `minimum_integer_digits` | Minimum integer digits |
| `minimumFractionDigits` | `minimum_fraction_digits` | Minimum decimal places |
| `maximumFractionDigits` | `maximum_fraction_digits` | Maximum decimal places |
| `useGrouping` | `use_grouping` | Enable/disable grouping separators |

**Examples**:

```ruby
# FTL
resource = Foxtail::Resource.from_string(<<~FTL)
  price = The price is { NUMBER($amount, style: "currency", currency: "USD") }.
  percent = { NUMBER($ratio, style: "percent") } complete
  padded = { NUMBER($num, minimumIntegerDigits: 3) }
FTL

bundle = Foxtail::Bundle.new(ICU4X::Locale.parse("en-US"))
bundle.add_resource(resource)

bundle.format("price", amount: 1234.50)    # "The price is $1,234.50."
bundle.format("percent", ratio: 0.75)      # "75% complete"
bundle.format("padded", num: 5)            # "005"
```

### DATETIME

Formats dates and times with locale awareness.

**FTL Syntax**:

```ftl
date = { DATETIME($timestamp, dateStyle: "long") }
time = { DATETIME($timestamp, timeStyle: "short") }
both = { DATETIME($timestamp, dateStyle: "medium", timeStyle: "short") }
```

**Options** (FTL → ICU4X mapping):

| FTL Option (camelCase) | ICU4X Option | Values |
|------------------------|--------------|--------|
| `dateStyle` | `date_style` | `:full`, `:long`, `:medium`, `:short` |
| `timeStyle` | `time_style` | `:full`, `:long`, `:medium`, `:short` |
| `timeZone` | `time_zone` | Timezone identifier |

**Examples**:

```ruby
# FTL
resource = Foxtail::Resource.from_string(<<~FTL)
created = Created on { DATETIME($date, dateStyle: "long") }
meeting = Meeting at { DATETIME($time, timeStyle: "short") }
FTL

bundle = Foxtail::Bundle.new(ICU4X::Locale.parse("en-US"))
bundle.add_resource(resource)

bundle.format("created", date: Time.new(2026, 1, 4))
# => "Created on January 4, 2026"

bundle.format("meeting", time: Time.new(2026, 1, 4, 14, 30))
# => "Meeting at 2:30 PM"
```

### Implicit Function Calling

Per the [Fluent specification](https://github.com/projectfluent/fluent/blob/main/guide/functions.md), numeric and time variables automatically receive locale-aware formatting when used in placeables:

```ftl
# Implicit NUMBER formatting - equivalent to { NUMBER($count) }
emails = You have { $count } emails.

# Implicit DATETIME formatting - equivalent to { DATETIME($date) }
created = Created on { $date }.
```

```ruby
bundle.format("emails", count: 1000)  # "You have 1,000 emails."

time = Time.new(2025, 1, 4)
bundle.format("created", date: time)  # "Created on Jan 4, 2025."
```

**Supported types for implicit formatting:**
- NUMBER: `Integer`, `Float`, `BigDecimal`
- DATETIME: `Time`, or any object responding to `#to_time` (e.g., `Date`)

Use explicit function calls when you need specific formatting options (currency, percent, date/time styles, etc.).

## Plural Rules

Foxtail uses ICU4X plural rules for select expressions with numeric selectors.

### CLDR Plural Categories

| Category | Used By |
|----------|---------|
| `zero` | Arabic, Latvian, etc. |
| `one` | English (1), French (0, 1), etc. |
| `two` | Arabic, Welsh, etc. |
| `few` | Russian (2-4), Polish (2-4), etc. |
| `many` | Russian (5-20), Polish (5-21), etc. |
| `other` | Default fallback |

### How Matching Works

```ftl
items =
    { $count ->
        [0] No items
        [one] One item
       *[other] { $count } items
    }
```

Resolution process:

1. Check for exact match (`[0]` matches if `$count == 0`)
2. Check plural category match (`[one]` matches if category is "one")
3. Fall back to default variant (`*[other]`)

### Locale Differences

```ruby
# English
en = ICU4X::Locale.parse("en")
en_rules = ICU4X::PluralRules.new(en)
en_rules.select(1)  # => :one
en_rules.select(2)  # => :other

# Russian (has complex plural rules)
ru = ICU4X::Locale.parse("ru")
ru_rules = ICU4X::PluralRules.new(ru)
ru_rules.select(1)   # => :one
ru_rules.select(2)   # => :few
ru_rules.select(5)   # => :many
ru_rules.select(21)  # => :one
ru_rules.select(22)  # => :few
```

## Custom Functions

You can register custom functions that use ICU4X:

```ruby
# Custom ordinal formatter
ordinal_function = ->(args, _options, scope) do
  value = args.first
  locale = scope.bundle.locale
  # Use ICU4X or custom logic
  case value
  when 1 then "1st"
  when 2 then "2nd"
  when 3 then "3rd"
  else "#{value}th"
  end
end

bundle = Foxtail::Bundle.new(locale, functions: {
  "ORDINAL" => ordinal_function
})
```

## Data Loading

`icu4x` data is loaded once at startup. Ensure `ICU4X_DATA_PATH` is set before any formatting operations.

## Error Handling

ICU4X errors are caught and reported through Foxtail's error system:

```ruby
# Invalid locale
bundle = Foxtail::Bundle.new(ICU4X::Locale.parse("invalid"))
# May raise ICU4X::Error

# Invalid currency
bundle.format("price", amount: 100) # With currency: "INVALID"
# Returns placeholder, error collected in scope
```

## Locale Fallback

Same-language locale fallback (e.g., `en-US` → `en`) is handled by `icu4x` provider. User language preference negotiation (multiple language fallback) is not yet implemented.

## References

- [ICU4X Project](https://github.com/unicode-org/icu4x)
- [icu4x Ruby Gem](https://github.com/sakuro/icu4x)
- [CLDR Plural Rules](https://cldr.unicode.org/index/cldr-spec/plural-rules)
- [Unicode Number Format](https://unicode-org.github.io/icu/userguide/format_parse/numbers/)
