# :fox_face: Foxtail Runtime :globe_with_meridians:

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

## ICU4X Data Setup

Foxtail uses the `icu4x` gem (Ruby bindings for [ICU4X](https://github.com/unicode-org/icu4x)).
Configure `ICU4X_DATA_PATH` to point at ICU4X data. For development in this repo:

```bash
$ bin/setup
```

See the [icu4x gem documentation](https://github.com/sakuro/icu4x) for details.

## Basic Usage

```ruby
require "foxtail-runtime"
require "icu4x"

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
```

## Documentation

- [Architecture](doc/architecture.md)
- [Bundle System](doc/bundle-system.md)
- [ICU4X Integration](doc/icu4x-integration.md)
- [Sequence](doc/sequence.md)

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
