# Language Fallback with Sequence

## Overview

`Foxtail::Sequence` manages ordered sequences of Bundles for language fallback. It finds the first bundle that contains a requested message, enabling fallback chains like `en-US` → `en` → default.

Equivalent to [@fluent/sequence](https://projectfluent.org/fluent.js/sequence/) in fluent.js.

## Basic Usage

```ruby
# Create bundles for different locales
en_us = Foxtail::Bundle.new(ICU4X::Locale.parse("en-US"))
en_us.add_resource(Foxtail::Resource.from_string("hello = Hello!"))

en = Foxtail::Bundle.new(ICU4X::Locale.parse("en"))
en.add_resource(Foxtail::Resource.from_string("hello = Hello!"))

ja = Foxtail::Bundle.new(ICU4X::Locale.parse("ja"))
ja.add_resource(Foxtail::Resource.from_string("hello = こんにちは！"))

# Create sequence in priority order
sequence = Foxtail::Sequence.new(en_us, en, ja)

# Format uses first matching bundle
sequence.format("hello") # => "Hello!"
```

## Language Fallback

When a message is not found in the primary bundle, Sequence automatically falls back to the next bundle:

```ruby
en_us.add_resource(Foxtail::Resource.from_string("us-only = US English"))
en.add_resource(Foxtail::Resource.from_string("en-only = English"))
ja.add_resource(Foxtail::Resource.from_string("ja-only = 日本語"))

sequence = Foxtail::Sequence.new(en_us, en, ja)

sequence.format("us-only")  # => "US English" (from en_us)
sequence.format("en-only")  # => "English" (from en, en_us doesn't have it)
sequence.format("ja-only")  # => "日本語" (from ja)
```

## Finding Bundles

Use `find` when you need to know which bundle contains a message:

```ruby
bundle = sequence.find("hello")
if bundle
  puts "Found in locale: #{bundle.locale}"
  bundle.format("hello", name: "World")
end
```

### Multiple IDs

Find bundles for multiple IDs at once:

```ruby
bundles = sequence.find("hello", "goodbye", "thanks")
# => [bundle_for_hello, bundle_for_goodbye, bundle_for_thanks]
# nil for IDs not found in any bundle
```

## API Reference

### `Sequence.new(*bundles)`

Creates a new Sequence with bundles in priority order.

```ruby
sequence = Foxtail::Sequence.new(primary, fallback1, fallback2)

# Also accepts an array
sequence = Foxtail::Sequence.new(bundle_array)
```

### `#find(*ids)`

Finds the first bundle containing each message ID.

| Arguments | Return |
|-----------|--------|
| Single ID | `Bundle` or `nil` |
| Multiple IDs | `Array<Bundle, nil>` |

```ruby
sequence.find("hello")           # => Bundle or nil
sequence.find("a", "b", "c")     # => [Bundle, nil, Bundle]
```

### `#format(id, **kwargs)`

Formats a message using the first matching bundle.

```ruby
sequence.format("hello", name: "World")
# => "Hello, World!"

sequence.format("nonexistent")
# => "nonexistent" (returns ID if not found)
```

Same signature as `Bundle#format` for duck-typing compatibility.

## Use Cases

### User Preference Chains

```ruby
# User prefers Japanese, falls back to English
user_bundles = [bundle_ja, bundle_en]
sequence = Foxtail::Sequence.new(user_bundles)
```

### Regional Variants

```ruby
# British English → Generic English → Default
sequence = Foxtail::Sequence.new(bundle_en_gb, bundle_en, bundle_default)
```

### Partial Translations

```ruby
# New locale with incomplete translations
# Falls back to complete locale
sequence = Foxtail::Sequence.new(bundle_new_locale, bundle_complete_locale)
```

## Example

See [examples/multilingual_app/](../foxtail-runtime/examples/multilingual_app/) for a complete working example with FTL files.
