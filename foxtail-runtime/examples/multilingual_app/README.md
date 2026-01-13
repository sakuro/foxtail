# Multilingual App Example

Demonstrates language fallback using `Foxtail::Sequence`.

## Features

- Loading FTL files from disk with `Resource.from_file`
- Using `Sequence` to create fallback chains
- Handling locale-specific messages

## Structure

```
multilingual_app/
  main.rb           # Main application code
  locales/
    en.ftl          # English translations
    ja.ftl          # Japanese translations
```

## Run

```bash
bundle exec ruby examples/multilingual_app/main.rb
```

## Key Concepts

### Language Fallback

When a message is missing in the primary locale, `Sequence` automatically falls back to the next bundle:

```ruby
# Japanese primary, English fallback
sequence = Foxtail::Sequence.new(ja_bundle, en_bundle)

# Found in Japanese bundle
sequence.format("hello", name: "太郎") # => こんにちは、太郎さん！

# Not in Japanese, falls back to English
sequence.format("english-only") # => This message is only available in English.
```

### Finding Bundles

Use `find` to determine which bundle contains a message:

```ruby
bundle = sequence.find("hello")
puts bundle.locale # => "ja"
```
