# Language Fallback with Sequence

## Overview

`Foxtail::Sequence` manages ordered sequences of Bundles for message-level language fallback. It finds the first bundle that contains a requested message, enabling fallback chains like `ja` → `en-US` → `en`. Formatting data resolution within each Bundle is handled separately by the `icu4x` provider (see [ICU4X Integration](icu4x-integration.md#locale-fallback)).

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
sequence = Foxtail::Sequence.new(ja, en_us, en)

# Format uses first matching bundle
sequence.format("hello") # => "こんにちは！"
```

## Language Fallback

When a message is not found in the primary bundle, Sequence automatically falls back to the next bundle:

```ruby
en_us.add_resource(Foxtail::Resource.from_string("us-only = US English"))
en.add_resource(Foxtail::Resource.from_string("en-only = English"))
ja.add_resource(Foxtail::Resource.from_string("ja-only = 日本語"))

sequence = Foxtail::Sequence.new(ja, en_us, en)

sequence.format("ja-only")  # => "日本語" (from ja)
sequence.format("us-only")  # => "US English" (from en_us, ja doesn't have it)
sequence.format("en-only")  # => "English" (from en, ja and en_us don't have it)
sequence.format("unknown")  # => "unknown" (returns ID if not found)
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

See [examples/multilingual_app/](../examples/multilingual_app/) for a complete working example with FTL files.
