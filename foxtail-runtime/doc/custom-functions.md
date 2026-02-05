# Custom Functions Guide

This guide explains how to create and register custom functions in Foxtail.

## Overview

Custom functions extend Foxtail's formatting capabilities beyond the built-in `NUMBER` and `DATETIME` functions. They allow you to implement domain-specific formatting logic for your application.

## Function Signature

Custom functions are objects that respond to `call`. This includes lambdas, procs, methods, and any custom object that implements the `call` method. The expected signature is:

```rbs
def call: (*Function::Value positional_args, **Function::Value options) -> (String | Function::Value)
```

### Parameters

| Parameter | Description |
|-----------|-------------|
| Positional arguments | `Foxtail::Function::Value` instances wrapping values from FTL |
| Named options | `Foxtail::Function::Value` instances wrapping option values |
| `**` | Catch-all for any additional keyword arguments |

**Important:** All arguments are wrapped as `Foxtail::Function::Value` (or subclasses like `Function::Number` for numeric values). This allows functions to access both the raw value and any formatting options. To get the raw value, use `.value`:

```ruby
->(wrapped_value, **) do
  raw = wrapped_value.value  # Extract raw value
  # ...
end
```

### Return Value

Custom functions can return either:

- A `String` - for simple text output
- A `Foxtail::Function::Value` instance (or subclass like `Foxtail::Function::Number`)

Use `Function::Number` when the result needs to participate in plural category matching:

```ruby
# Simple text: String is fine
shout = ->(text, **) { text.to_s.upcase }

# Numeric value for plural matching: Use Function::Number
item_count = ->(count, **) do
  Foxtail::Function::Number.new(count)
end
```

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
shout = ->(text, **) { text.value.to_s.upcase }

bundle = Foxtail::Bundle.new(locale, functions: { "SHOUT" => shout })
bundle.add_resource("greeting = Hello, { SHOUT($name) }!")
bundle.format("greeting", name: "world")  # => "Hello, WORLD!"
```

### Function with Options

```ruby
# FTL: price = { PRICE($amount, currency: "USD") }
format_price = ->(amount, currency:, **) do
  # Unwrap Function::Value arguments
  raw_amount = amount.value
  raw_currency = currency.value
  Foxtail::Function::Number.new(raw_amount, style: :currency, currency: raw_currency)
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

  private def unwrap(value) = value.is_a?(Foxtail::Function::Value) ? value.value : value

  private def format_item(item_id, **)
    item_id = unwrap(item_id)
    resolve_item(item_id, 1)
  end

  private def format_item_with_count(item_id, count, **)
    item_id = unwrap(item_id)
    count = unwrap(count)
    "#{count} #{resolve_item(item_id, count)}"
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

See the [dungeon game example](../examples/dungeon_game/) for a comprehensive implementation of custom functions handling:

- Locale-specific item names with grammatical cases
- Counter words (e.g., Japanese counters)
- Article handling (definite/indefinite)
- Pluralization

Key files:
- `examples/dungeon_game/functions/handler.rb` - Base handler class with unwrap helper
- `examples/dungeon_game/functions/en_handler.rb` - English-specific handling
- `examples/dungeon_game/functions/ja_handler.rb` - Japanese-specific handling
- `examples/dungeon_game/functions/item.rb` - ITEM function factory
- `examples/dungeon_game/functions/item_with_count.rb` - ITEM_WITH_COUNT function factory

## Best Practices

1. **Unwrap `Function::Value` arguments** - Use `.value` to get raw values from wrapped arguments
2. **Use `Function::Number` for numeric results** - Required for plural category matching
3. **Always accept `**`** - Future Foxtail versions may pass additional arguments
4. **Use `ICU4XCache`** - Avoid creating new ICU4X instances per call
5. **Handle errors gracefully** - Return a sensible fallback on errors
6. **Keep functions pure** - Avoid side effects for predictable behavior
7. **Document your functions** - Especially the expected FTL syntax
