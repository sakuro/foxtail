# :fox_face: Foxtail :globe_with_meridians:

A Ruby implementation of [Project Fluent](https://projectfluent.org/) - a modern localization system designed to improve how software is translated.

## Features

- **High fluent.js compatibility** - 97/98 official test fixtures passing
- **Runtime message formatting** - Bundle system with CLDR support
- **FTL syntax parser** - Full syntax support with error recovery
- **Multi-language support** - Number, date, and pluralization formatting
- **Ruby-native implementation** - Clean API following Ruby conventions

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

en_bundle = Foxtail::Bundle.new(Locale::Tag.parse("en-US"))
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

ja_bundle = Foxtail::Bundle.new(Locale::Tag.parse("ja"))
ja_bundle.add_resource(ja_resource)
ja_bundle.format("hello", name: "太郎")
# => "こんにちは、太郎さん！"
ja_bundle.format("emails", count: 1)
# => "メールが1件あります。"
```

### Advanced Features

Numbers, dates, and currencies with international formatting. Foxtail supports JavaScript Intl API and Ruby CLDR implementations, providing locale-specific formatting rules for numbers, dates, currencies, and pluralization across 200+ locales:

```ruby
# English (US)
en_resource = Foxtail::Resource.from_string(<<~FTL)
  price = The price is {NUMBER($amount, style: "currency", currency: "USD")}.
  discount = Sale: {NUMBER($percent, style: "percent")} off!
FTL

en_bundle = Foxtail::Bundle.new(Locale::Tag.parse("en-US"))
en_bundle.add_resource(en_resource)
en_bundle.format("price", amount: 1234.50)
# => "The price is $1,234.50."
en_bundle.format("discount", percent: 0.15)
# => "Sale: 15% off!"

# Japanese
ja_resource = Foxtail::Resource.from_string(<<~FTL)
  price = 価格は{NUMBER($amount, style: "currency", currency: "JPY")}です。
  discount = セール：{NUMBER($percent, style: "percent")}オフ！
FTL

ja_bundle = Foxtail::Bundle.new(Locale::Tag.parse("ja"))
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

# Currency names with custom pattern
currency_resource = Foxtail::Resource.from_string(<<~FTL)
  price-name = {NUMBER($amount, pattern: "#,##0.00 ¤¤¤", currency: "USD")}
FTL

en_bundle.add_resource(currency_resource)
en_bundle.format("price-name", amount: 100)
# => "100.00 US dollars"
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

### Compatibility Testing

```bash
# Test compatibility with fluent.js (97/98 passing)
$ bundle exec rake compatibility:report
```

### CLDR Data Extraction

```bash
# Extract CLDR data for development
$ bundle exec rake cldr:extract
```

### Code Quality

```bash
# Run all checks (tests + linting)
$ bundle exec rake
```

## Architecture

- **Parser System** - FTL syntax parsing and AST implementation
- **Bundle System** - Runtime message formatting with CLDR integration

## Documentation

- [Implementation Decisions](docs/plans/implementation_decisions.md) - Key architectural decisions and rationale
- [fluent.js Analysis](docs/plans/fluent_js_analysis.md) - Technical analysis of fluent.js architecture

## Compatibility

- **Ruby**: 3.2.9 or higher
- **fluent.js**: 97/98 test fixtures passing (99.0%)

## Function Backends

Foxtail supports two backends for NUMBER and DATETIME functions:

### Automatic Backend Selection

```ruby
# Auto-detect (default behavior)
Foxtail::Function.backend = :auto
# => Uses JavaScript if ExecJS runtime available, otherwise Foxtail::Intl
```

### Backend Comparison

| Backend | Performance | Standards Compliance | Requirements |
|---------|-------------|---------------------|--------------|
| **JavaScript** | Depends on runtime* | Excellent (Intl API) | JavaScript runtime |
| **Foxtail::Intl** | Very fast | Good (Ruby CLDR) | None |

*JavaScript backend performance depends on the ExecJS runtime:
- **Embedded engines** (mini_racer): Fast, direct V8 integration
  - Number formatting: ~5-6x slower than Foxtail::Intl
  - DateTime formatting: ~1.7x slower than Foxtail::Intl
- **External engines** (Node.js): Much slower due to process communication overhead
  - Can be 100-1000x slower than Foxtail::Intl for number formatting

### Manual Backend Selection

```ruby
# Use JavaScript backend (better standards compliance)
Foxtail::Function.backend = :javascript

# Use Foxtail::Intl backend (better performance)
Foxtail::Function.backend = :foxtail_intl
```

### Accuracy Considerations

The JavaScript backend provides better compliance with international standards, especially for complex locales with specialized formatting rules:
- **Indian (hi-IN)**: Correct lakh/crore grouping (12,34,567 vs 1,234,567)
- **Persian (fa-IR)**: Solar Hijri calendar support
- **Thai (th-TH)**: Buddhist Era (พ.ศ.) year display

The Foxtail::Intl backend offers significantly better performance with good accuracy for most use cases.

Both backends work seamlessly through the Bundle system:

```ruby
# Same code works with either backend
bundle.format("price", amount: 1234.56)
# JavaScript: Uses native Intl.NumberFormat
# Foxtail::Intl: Uses Ruby CLDR implementation
```

## Performance

- **Message resolution**: Fast with efficient CLDR data handling
- **Function backends**: Choose based on your performance vs accuracy requirements

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/sakuro/foxtail.

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Run the tests (`bundle exec rake spec`)
4. Commit your changes (`git commit -am 'Add some feature'`)
5. Push to the branch (`git push origin my-new-feature`)
6. Create new Pull Request

## Acknowledgments

This project stands on the shoulders of giants:

- **Unicode CLDR**: The plural rules data is extracted from [Unicode Common Locale Data Repository (CLDR) v34](http://unicode.org/Public/cldr/34/core.zip), providing ICU-compliant plural rules for 207 locales ([Unicode License v3](https://opensource.org/license/unicode-license-v3))
- **Fluent Project**: Foxtail aims for compatibility with Mozilla's [Fluent localization system](https://projectfluent.org/), particularly [fluent.js](https://github.com/projectfluent/fluent.js) ([Apache 2.0](https://www.apache.org/licenses/LICENSE-2.0.txt))
- **ICU Project**: Plural rules implementation follows [ICU plural rules specification](https://unicode.org/reports/tr35/tr35-numbers.html#Language_Plural_Rules) ([Unicode License v3](https://opensource.org/license/unicode-license-v3))
- **Ruby Locale**: Locale parsing and handling provided by the [Ruby GetText project](https://ruby-gettext.github.io/) ([Ruby License](https://www.ruby-lang.org/en/about/license.txt))

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
