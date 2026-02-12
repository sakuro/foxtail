# 🦊 Foxtail Tools 🌐

Tooling for authoring and validating [Project Fluent](https://projectfluent.org/) files in Ruby.

## Features

- Full syntax parser with spans and comments
- Serializer for round-trip formatting
- CLI tools: check, dump, ids, tidy

## Installation

Add this line to your application's Gemfile:

```ruby
gem "foxtail-tools"
```

Then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install foxtail-tools
```

## Usage

### CLI

```bash
foxtail check messages.ftl
foxtail dump messages.ftl
foxtail ids messages.ftl
foxtail tidy messages.ftl
```

See [doc/cli.md](doc/cli.md) for the full CLI reference.

### Syntax API

```ruby
require "foxtail-tools"

parser = Foxtail::Syntax::Parser.new
ast = parser.parse("hello = Hello")
```

## Compatibility

The syntax parser passes 97 of 98 [fluent-syntax](https://github.com/projectfluent/fluent.js/tree/main/fluent-syntax) test fixtures (99.0%).

The `leading_dots` fixture is a known mismatch — this test also fails in fluent.js itself.

## Documentation

- [CLI Reference](doc/cli.md)
- [Architecture](doc/architecture.md)

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
