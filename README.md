# :fox_face: Foxtail :globe_with_meridians:

A Ruby implementation of [Project Fluent](https://projectfluent.org/) - a modern localization system designed to improve how software is translated.

## Features

- **fluent.js compatibility** - 97/98 official test fixtures passing
- **Runtime message formatting** - Bundle system with `icu4x`-based formatting
- **FTL syntax parser** - Syntax support with error recovery
- **Multi-language support** - Number, date, and pluralization formatting
- **Ruby implementation** - API following Ruby conventions

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'foxtail'
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install foxtail
```

## Quick Start

### `icu4x` Gem Setup

Foxtail uses the `icu4x` gem (Ruby bindings for [ICU4X](https://github.com/unicode-org/icu4x)), which requires data configuration:

1. The `icu4x-data-recommended` gem is included as a development dependency
2. Run `bin/setup` to configure the `ICU4X_DATA_PATH` environment variable in `.env`

For details, see the [icu4x gem documentation](https://github.com/sakuro/icu4x).

### Basic Usage

```ruby
require 'foxtail'

# English (US)
en_resource = Foxtail::Resource.from_string(<<~FTL)
  hello = Hello, {$name}!
  emails = You have {$count ->
    [0] no emails
    [one] one email
   *[other] {$count} emails
  }.
FTL

en_bundle = Foxtail::Bundle.new(ICU4X::Locale.parse("en-US"))
en_bundle.add_resource(en_resource)
en_bundle.format("hello", name: "Alice")
# => "Hello, Alice!"
en_bundle.format("emails", count: 1)
# => "You have one email."

# Japanese
ja_resource = Foxtail::Resource.from_string(<<~FTL)
  hello = こんにちは、{$name}さん！
  emails = メールが{$count}件あります。
FTL

ja_bundle = Foxtail::Bundle.new(ICU4X::Locale.parse("ja"))
ja_bundle.add_resource(ja_resource)
ja_bundle.format("hello", name: "太郎")
# => "こんにちは、太郎さん！"
ja_bundle.format("emails", count: 1)
# => "メールが1件あります。"
```

### Advanced Features

Numbers, dates, and currencies with international formatting using `icu4x`:

```ruby
# English (US)
en_resource = Foxtail::Resource.from_string(<<~FTL)
  price = The price is {NUMBER($amount, style: "currency", currency: "USD")}.
  discount = Sale: {NUMBER($percent, style: "percent")} off!
FTL

en_bundle = Foxtail::Bundle.new(ICU4X::Locale.parse("en-US"))
en_bundle.add_resource(en_resource)
en_bundle.format("price", amount: 1234.50)
# => "The price is $1,234.5."
en_bundle.format("discount", percent: 0.15)
# => "Sale: 15% off!"

# Japanese
ja_resource = Foxtail::Resource.from_string(<<~FTL)
  price = 価格は{NUMBER($amount, style: "currency", currency: "JPY")}です。
  discount = セール：{NUMBER($percent, style: "percent")}オフ！
FTL

ja_bundle = Foxtail::Bundle.new(ICU4X::Locale.parse("ja"))
ja_bundle.add_resource(ja_resource)
ja_bundle.format("price", amount: 1234)
# => "価格は￥1,234です。"
ja_bundle.format("discount", percent: 0.15)
# => "セール：15%オフ！"

# Pattern selection with strings
pattern_resource = Foxtail::Resource.from_string(<<~FTL)
  greeting = {$gender ->
    [male] Hello, Mr. {$name}!
    [female] Hello, Ms. {$name}!
   *[other] Hello, {$name}!
  }
FTL

en_bundle.add_resource(pattern_resource)
en_bundle.format("greeting", gender: "male", name: "John")
# => "Hello, Mr. John!"
```


## Development

After checking out the repo, run:

```bash
$ bin/setup
```

This will install dependencies and set up the fluent.js submodule for compatibility testing.

### Running Tests

```bash
# Run all tests
$ bundle exec rake spec
```

### Code Quality

```bash
# Run all checks (tests + linting)
$ bundle exec rake
```

## Architecture

- **Parser System** - FTL syntax parsing and AST implementation
- **Bundle System** - Runtime message formatting with `icu4x` integration

## Compatibility

- **Ruby**: 3.2 or higher
- **fluent.js**: 97/98 test fixtures passing (99.0%)

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/sakuro/foxtail.

1. Fork it
2. Create your feature branch (`git checkout -b feature/add-some-feature`)
3. Run the tests (`bundle exec rake spec`)
4. Commit your changes (`git commit -am ':sparkles: Add some feature'`)
5. Push to the branch (`git push origin feature/add-some-feature`)
6. Create new Pull Request

## Acknowledgments

This project stands on the shoulders of giants:

- **[ICU4X](https://github.com/unicode-org/icu4x)**: Number, date/time, plural rules, and locale handling
- **Fluent Project**: Foxtail aims for compatibility with Mozilla's [Fluent localization system](https://projectfluent.org/), particularly [fluent.js](https://github.com/projectfluent/fluent.js) ([Apache 2.0](https://www.apache.org/licenses/LICENSE-2.0.txt))

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
