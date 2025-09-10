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

# Create a bundle for a specific locale
locale = Locale::Tag.parse("en-US")
bundle = Foxtail::Bundle.new(locale)

# Load FTL resources
resource = Foxtail::Resource.from_string(<<~FTL)
  hello = Hello, {$name}!
  emails = You have {$count ->
    [0] no emails
    [one] one email
   *[other] {$count} emails
  }.
FTL

bundle.add_resource(resource)

# Format messages
bundle.format("hello", name: "Alice")
# => "Hello, Alice!"

bundle.format("emails", count: 0)
# => "You have no emails."

bundle.format("emails", count: 1)
# => "You have one email."

bundle.format("emails", count: 5)
# => "You have 5 emails."
```

### Advanced Features

```ruby
# Numbers and dates with CLDR formatting
resource = Foxtail::Resource.from_string(<<~FTL)
  price = The price is {NUMBER($amount)}.
  discount = Sale: {NUMBER($percent, style: "percent")} off!
  deadline = Deadline: {DATETIME($date, dateStyle: "long")}.
FTL

bundle.add_resource(resource)
bundle.format("price", amount: 42.99)
# => "The price is 42.99."

bundle.format("discount", percent: 0.15)
# => "Sale: 15% off!"

# Note: Currency formatting (style: "currency", currency: "USD") is not yet fully implemented
# Currently uses simplified formatting with default "$" symbol

# Terms and references
resource = Foxtail::Resource.from_string(<<~FTL)
  -brand = Foxtail
  welcome = Welcome to {-brand}!
  title = {-brand} - Ruby Localization
FTL

bundle.add_resource(resource)
bundle.format("welcome")
# => "Welcome to Foxtail!"
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

# Run specific test types
$ bundle exec rspec spec/foxtail/parser_spec.rb
$ bundle exec rspec spec/foxtail/bundle_spec.rb
```

### Compatibility Testing

Foxtail includes comprehensive compatibility testing against fluent.js:

```bash
# Generate compatibility report (97/98 fixtures passing, 99.0%)
$ bundle exec rake compatibility:report
```

### Code Quality

```bash
# Run linter
$ bundle exec rake rubocop

# Auto-fix issues
$ bundle exec rubocop -a

# Run all checks (tests + linting)
$ bundle exec rake
```

## Architecture

Foxtail consists of two main components:

### Parser System
- **Foxtail::Parser** - FTL syntax parser
- **Foxtail::Parser::AST** - Abstract Syntax Tree implementation
- **Foxtail::Parser::Stream** - Character stream processing

### Bundle System
- **Foxtail::Bundle** - Runtime message formatting
- **Foxtail::Resource** - FTL resource loading and management
- **Foxtail::Functions** - Built-in formatting functions (NUMBER, DATETIME)
- **Foxtail::CLDR** - Unicode CLDR integration

## Documentation

- [Implementation Decisions](docs/plans/implementation_decisions.md) - Key architectural decisions and rationale
- [fluent.js Analysis](docs/plans/fluent_js_analysis.md) - Technical analysis of fluent.js architecture

## Compatibility

- **Ruby**: 3.2.9 or higher
- **fluent.js**: High compatibility (97/98 test fixtures passing)
- **Unicode**: Full Unicode support including astral plane characters
- **CLDR**: Unicode CLDR integration for localization

## Performance

Foxtail focuses on runtime efficiency:
- Fast message resolution
- Parsing done at resource load time
- Efficient CLDR data handling

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
