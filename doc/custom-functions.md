# Custom Functions Guide

This guide explains how to create and register custom functions in Foxtail.

## Overview

Custom functions extend Foxtail's formatting capabilities beyond the built-in `NUMBER` and `DATETIME` functions. They allow you to implement domain-specific formatting logic for your application.

## Function Signature

Custom functions are callable objects (lambdas, procs, or methods) with the following signature:

```ruby
->(positional_arg1, positional_arg2, ..., locale:, option1:, option2:, **) { ... }
```

### Parameters

| Parameter | Description |
|-----------|-------------|
| Positional arguments | Values passed from FTL (e.g., `{ FUNC($var) }` passes the value of `$var`) |
| `locale:` | `ICU4X::Locale` instance from the bundle (always provided) |
| Named options | Options from FTL (e.g., `{ FUNC($var, style: "short") }`) |
| `**` | Catch-all for any additional keyword arguments |

### Important

Always include `**` in your function signature to accept additional keyword arguments that Foxtail may pass.

## Registering Functions

Pass functions to `Bundle.new` via the `functions:` option:

```ruby
locale = ICU4X::Locale.parse("en-US")

bundle = Foxtail::Bundle.new(locale, functions: {
  "SHOUT" => ->(text, **) { text.to_s.upcase },
  "CURRENCY" => method(:format_currency)
})
```

## Examples

### Simple Function

```ruby
# FTL: greeting = Hello, { SHOUT($name) }!
shout = ->(text, **) { text.to_s.upcase }

bundle = Foxtail::Bundle.new(locale, functions: { "SHOUT" => shout })
bundle.add_resource("greeting = Hello, { SHOUT($name) }!")
bundle.format("greeting", name: "world")  # => "Hello, WORLD!"
```

### Function with Options

```ruby
# FTL: price = { PRICE($amount, currency: "USD") }
format_price = ->(amount, locale:, currency: "USD", **) do
  formatter = Foxtail::ICU4XCache.instance.number_formatter(
    locale,
    style: :currency,
    currency: currency
  )
  formatter.format(amount)
end

bundle = Foxtail::Bundle.new(locale, functions: { "PRICE" => format_price })
```

### Class-based Functions

For complex functions, use a class with instance methods:

```ruby
class ItemFormatter
  def initialize(items_bundle)
    @items_bundle = items_bundle
  end

  def functions
    {
      "ITEM" => method(:format_item),
      "ITEM_WITH_COUNT" => method(:format_item_with_count)
    }
  end

  private def format_item(item_id, locale:, **)
    # Implementation
  end

  private def format_item_with_count(item_id, count, locale:, **)
    formatted_count = Foxtail::ICU4XCache.instance.number_formatter(locale).format(count)
    "#{formatted_count} #{resolve_item(item_id, count)}"
  end
end

# Usage
formatter = ItemFormatter.new(items_bundle)
bundle = Foxtail::Bundle.new(locale, functions: formatter.functions)
```

## Using ICU4XCache

When your custom function needs ICU4X formatters or plural rules, use `Foxtail::ICU4XCache` for efficient instance reuse:

```ruby
cache = Foxtail::ICU4XCache.instance

# Number formatting
formatter = cache.number_formatter(locale)
formatter = cache.number_formatter(locale, style: :percent)
formatter = cache.number_formatter(locale, style: :currency, currency: "JPY")

# DateTime formatting
formatter = cache.datetime_formatter(locale, date_style: :long)
formatter = cache.datetime_formatter(locale, date_style: :short, time_style: :short)

# Plural rules
rules = cache.plural_rules(locale)
rules = cache.plural_rules(locale, type: :ordinal)
```

### Why Use ICU4XCache?

ICU4X formatters and rules load and parse locale data on instantiation. `ICU4XCache` caches these instances by locale and options, providing significant performance benefits:

| Operation | Direct | Cached | Speedup |
|-----------|--------|--------|---------|
| NumberFormat | ~13μs | ~0.8μs | 16x |
| DateTimeFormat | ~7μs | ~0.8μs | 9x |
| PluralRules | ~5μs | ~0.5μs | 10x |

The cache is thread-safe and process-global.

## Real-World Example

See the [dungeon game example](../foxtail-runtime/examples/dungeon_game/) for a comprehensive implementation of custom functions handling:

- Locale-specific item names with grammatical cases
- Counter words (e.g., Japanese counters)
- Article handling (definite/indefinite)
- Pluralization

Key files:
- `foxtail-runtime/examples/dungeon_game/functions/base.rb` - Base function class
- `foxtail-runtime/examples/dungeon_game/functions/en.rb` - English-specific handling
- `foxtail-runtime/examples/dungeon_game/functions/ja.rb` - Japanese-specific handling

## Best Practices

1. **Always accept `**`** - Future Foxtail versions may pass additional arguments
2. **Use `ICU4XCache`** - Avoid creating new ICU4X instances per call
3. **Handle errors gracefully** - Return a sensible fallback on errors
4. **Keep functions pure** - Avoid side effects for predictable behavior
5. **Document your functions** - Especially the expected FTL syntax
