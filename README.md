# :fox_face: Foxtail :globe_with_meridians:

A Ruby implementation of [Project Fluent](https://projectfluent.org/) with two gems:

- **foxtail-runtime**: runtime bundle parsing + message formatting
- **foxtail-tools**: CLI + full syntax parser/serializer

## Gems

### foxtail-runtime

Runtime formatting with ICU4X integration and fluent.js-compatible bundle parsing.

### foxtail-tools

Tooling for authoring and validating FTL files (CLI + full syntax parser/serializer).

## Installation

Add the gems you need to your application's Gemfile:

```ruby
gem "foxtail-runtime"
# Optional tooling (CLI + syntax parser)
gem "foxtail-tools"
```

Then install:

```bash
$ bundle install
```

Require entry points based on what you use:

```ruby
require "foxtail-runtime" # Runtime APIs
require "foxtail-tools"   # CLI + tooling APIs
```

## Quick Start (runtime)

```ruby
require "foxtail-runtime"

resource = Foxtail::Resource.from_string(<<~FTL)
  hello = Hello, { $name }!
  emails =
      You have { $count ->
          [one] one email
         *[other] { $count } emails
      }.
FTL

bundle = Foxtail::Bundle.new(ICU4X::Locale.parse("en-US"))
bundle.add_resource(resource)

bundle.format("hello", name: "Alice")
# => "Hello, Alice!"

bundle.format("emails", count: 1)
# => "You have one email."

bundle.format("emails", count: 5)
# => "You have 5 emails."
```

## CLI (tools)

```bash
foxtail check messages.ftl
foxtail dump messages.ftl
foxtail ids messages.ftl
foxtail tidy messages.ftl
```

See [foxtail-tools/doc/cli.md](foxtail-tools/doc/cli.md) for full CLI reference.

## Development

After checking out the repo, run:

```bash
$ bin/setup
```

This installs dependencies, configures ICU4X data, and initializes the fluent.js submodule.

### Running Tests

```bash
# All tests
$ bundle exec rake spec

# Per gem
$ bundle exec rake spec:runtime
$ bundle exec rake spec:tools
```

### Code Quality

```bash
$ bundle exec rake rubocop
```

## Architecture

Foxtail is split into two gems with distinct responsibilities:

- **`foxtail-runtime`**: Runtime components (bundle parsing, message formatting, ICU4X integration)
- **`foxtail-tools`**: Tooling components (syntax parser/serializer and CLI)

Architecture notes per gem:

- [Runtime Architecture](foxtail-runtime/doc/architecture.md)
- [Tools Architecture](foxtail-tools/doc/architecture.md)

Related docs:

- **[Parser System](foxtail-tools/doc/ftl-syntax.md)** - FTL syntax parsing and AST implementation
- **[Bundle System](foxtail-runtime/doc/bundle-system.md)** - Runtime message formatting with [icu4x integration](foxtail-runtime/doc/icu4x-integration.md)
- **[Sequence](foxtail-runtime/doc/sequence.md)** - Language fallback chains
- **[Language Negotiation](foxtail-runtime/doc/language-negotiation.md)** - Accept-Language handling and safe fallback guidelines

## Compatibility

- **Ruby**: 3.2 or higher
- **fluent.js**: 159/160 test fixtures passing (99.4%)
  - Syntax parser: 97/98 (99.0%)
  - Bundle parser: 62/62 (100%)

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
