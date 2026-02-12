# 🦊 Foxtail Runtime 🌐

Runtime components for [Project Fluent](https://projectfluent.org/) localization in Ruby.

## Features

- Bundle parsing and runtime message formatting
- ICU4X-based number, date/time, and plural rules formatting
- Fluent.js-compatible runtime AST

## Installation

Add this line to your application's Gemfile:

```ruby
gem "foxtail-runtime"
```

Then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install foxtail-runtime
```

## Basic Usage

```ruby
require "foxtail-runtime"
require "icu4x-data-recommended" # for locale-aware NUMBER formatting

resource = Foxtail::Resource.from_string(<<~FTL)
  hello = Hello, { $name }!
  price = { NUMBER($amount, style: "currency", currency: "USD") }
FTL

bundle = Foxtail::Bundle.new(ICU4X::Locale.parse("en-US"))
bundle.add_resource(resource)

bundle.format("hello", name: "Alice")
# => "Hello, Alice!"

bundle.format("price", amount: 1234.5)
# => "$1,234.5"
```

## Documentation

- [Architecture](doc/architecture.md)
- [Bundle System](doc/bundle-system.md)
- [ICU4X Integration](doc/icu4x-integration.md)
- [Sequence](doc/sequence.md)

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
