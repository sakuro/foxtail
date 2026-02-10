# ICU4X Integration

## Overview

Foxtail uses the `icu4x` gem (Ruby bindings for [ICU4X](https://github.com/unicode-org/icu4x)) for locale-aware formatting. ICU4X is a Unicode Consortium project providing modern internationalization support.

## Setup

### Dependencies

The `icu4x` gem requires data files for locale-specific formatting rules. See the [icu4x gem documentation](https://github.com/sakuro/icu4x?tab=readme-ov-file#data-preparation) for data setup options.

## Components Used

| Component | Purpose |
|-----------|---------|
| `ICU4X::Locale` | Locale parsing and management |
| `ICU4X::NumberFormat` | Number formatting (decimal, currency, percent) |
| `ICU4X::DateTimeFormat` | Date/time formatting |
| `ICU4X::PluralRules` | CLDR plural category selection |

These components are used internally by the built-in functions below.

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

## Data Loading

ICU4X data is loaded once at startup. Ensure data is configured before any formatting operations.

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

Same-language locale fallback (e.g., `en-US` → `en`) is handled by the `icu4x` provider. This applies to formatting data resolution within a single Bundle. For message-level fallback across multiple locales, see [Language Fallback with Sequence](sequence.md).

## References

- [ICU4X Project](https://github.com/unicode-org/icu4x)
- [icu4x Ruby Gem](https://github.com/sakuro/icu4x)
- [CLDR Plural Rules](https://cldr.unicode.org/index/cldr-spec/plural-rules)
- [Unicode Number Format](https://unicode-org.github.io/icu/userguide/format_parse/numbers/)
