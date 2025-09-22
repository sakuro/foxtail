# NumberFormatter Modularization Design

## Overview

This document outlines the design for splitting the current monolithic `NumberFormatter` class into specialized, modular components. The design follows ICU4X's modular philosophy while maintaining the functionality and performance of the current implementation.

## Current State Analysis

### Existing NumberFormatter Structure

The current `NumberFormatter` class in `lib/foxtail/intl/number_format.rb` handles multiple formatting styles through a single, unified interface:

#### Core Processing Flow
1. **Initialization**: Style-dependent repository initialization (`@currencies`, `@units`, `@formats`)
2. **Pattern Determination**: Style-based pattern selection
3. **Value Transformation**: Style-specific transformations (currency rounding, percentage multiplication)
4. **Formatting**: Unified token-based formatting process

#### Style-Based Branching Points
- **6 locations** with `@options[:style]` conditional branching
- **3 repositories** conditionally initialized based on style
- **Unified token processing** with style-specific post-processing

#### Conditional Repository Loading
```ruby
# Initialize Currency repository if needed
if use_currency?(options)
  @currencies = Foxtail::CLDR::Repository::Currencies.new(locale)
end

# Initialize Units repository if needed
if use_units?(options)
  @units = Foxtail::CLDR::Repository::Units.new(locale)
end
```

## Modular Design Architecture

### 1. Foundation Component

#### FixedDecimalFormatter (Base Formatter)

```ruby
# Core decimal formatting foundation
class FixedDecimalFormatter
  def initialize(locale:, numbering_system: nil, **options)
    @locale = locale
    @formats = Foxtail::CLDR::Repository::NumberFormats.new(locale)
    @numbering_system = numbering_system || determine_numbering_system
    @digit_mapper = DigitMapper.new(@numbering_system) if @numbering_system != "latn"
  end

  def format_decimal(decimal_value, pattern_info)
    # Core decimal formatting logic:
    # - Integer grouping
    # - Fractional part processing
    # - Numbering system conversion
  end

  def format_with_pattern(decimal_value, pattern, &token_handler)
    # Pattern-based formatting:
    # - Pattern parsing
    # - Token processing with custom handlers
    # - Special value handling
  end

  def format_special_value(value)
    # Handle Infinity, -Infinity, NaN
  end

  def apply_digit_conversion(text)
    # Numbering system digit conversion
  end
end
```

### 2. Specialized Formatters

#### CurrencyFormatter

```ruby
# Currency-specific formatter
class CurrencyFormatter
  include Formatter

  def initialize(locale:, currency:, display: :symbol, **options)
    @base_formatter = FixedDecimalFormatter.new(locale: locale, **options)
    @currencies = Foxtail::CLDR::Repository::Currencies.new(locale)
    @currency = currency
    @display = display # :symbol, :code, :name
    @options = options
  end

  def format(amount)
    # Currency-specific processing:
    # - Apply currency-specific decimal places
    # - Handle currency symbol/name resolution
    # - Apply plural rules for currency names

    decimal_value = apply_currency_precision(amount)
    pattern = determine_currency_pattern

    @base_formatter.format_with_pattern(decimal_value, pattern) do |token|
      format_currency_token(token)
    end
  end

  private

  def apply_currency_precision(amount)
    currency_digits = @currencies.currency_digits(@currency)
    # Currency-specific rounding logic
    if currency_digits == 0
      BigDecimal(amount.round(0).to_s)
    else
      BigDecimal(amount.to_s)
    end
  end

  def determine_currency_pattern
    currency_style = @options[:currencyDisplay] == "accounting" ? "accounting" : "standard"
    @base_formatter.formats.currency_pattern(currency_style, @base_formatter.numbering_system)
  end

  def format_currency_token(token)
    case token
    when PatternParser::Number::CurrencyToken
      case @display
      when :symbol then @currencies.currency_symbol(@currency)
      when :code then @currency
      when :name
        plural_category = determine_plural_category
        @currencies.currency_name(@currency, plural_category)
      end
    else
      token
    end
  end
end
```

#### PercentFormatter

```ruby
# Percentage-specific formatter
class PercentFormatter
  include Formatter

  def initialize(locale:, **options)
    @base_formatter = FixedDecimalFormatter.new(locale: locale, **options)
    @options = options
  end

  def format(ratio)
    # Percentage-specific processing:
    # - 100x multiplication
    # - Percentage symbol application

    decimal_value = ratio * 100
    pattern = @base_formatter.formats.percent_pattern("standard", @base_formatter.numbering_system)

    @base_formatter.format_with_pattern(decimal_value, pattern)
  end
end
```

#### UnitFormatter

```ruby
# Unit measurement formatter
class UnitFormatter
  include Formatter

  def initialize(locale:, unit:, display: :short, **options)
    @base_formatter = FixedDecimalFormatter.new(locale: locale, **options)
    @units = Foxtail::CLDR::Repository::Units.new(locale)
    @unit = unit
    @display = display # :long, :short, :narrow
    @options = options
  end

  def format(amount)
    # Unit-specific processing:
    # - Unit pattern application
    # - Plural form handling

    formatted_number = @base_formatter.format_decimal(amount, base_pattern_info)
    plural_category = determine_plural_category(amount)
    unit_pattern = @units.unit_pattern(@unit, @display, plural_category)

    if unit_pattern
      unit_pattern.gsub("{0}", formatted_number)
    else
      "#{formatted_number} #{@unit}"
    end
  end

  private

  def base_pattern_info
    pattern = @base_formatter.formats.decimal_pattern("standard", @base_formatter.numbering_system)
    @base_formatter.analyze_pattern_structure(
      PatternParser::Number.new.parse(pattern)
    )
  end
end
```

#### ScientificFormatter

```ruby
# Scientific notation formatter
class ScientificFormatter
  include Formatter

  def initialize(locale:, notation: :scientific, **options)
    @base_formatter = FixedDecimalFormatter.new(locale: locale, **options)
    @notation = notation # :scientific, :engineering
    @options = options
  end

  def format(value)
    # Scientific notation processing:
    # - Exponent normalization
    # - Mantissa/exponent separation
    # - E-notation formatting

    normalized = normalize_for_notation(value)
    pattern = build_scientific_pattern

    @base_formatter.format_with_pattern(normalized[:mantissa], pattern) do |token|
      format_scientific_token(token, normalized[:exponent])
    end
  end

  private

  def normalize_for_notation(value)
    case @notation
    when :engineering
      normalize_for_engineering(value)
    else
      normalize_for_scientific(value)
    end
  end

  def normalize_for_scientific(value)
    # Normalize to mantissa between 1-10
    return { mantissa: BigDecimal(0), exponent: 0 } if value.zero?

    abs_value = value.abs
    exponent = bigdecimal_log10(abs_value).floor
    mantissa = abs_value / (BigDecimal(10) ** exponent)
    mantissa = -mantissa if value.negative?

    { mantissa: mantissa, exponent: exponent }
  end

  def normalize_for_engineering(value)
    # Normalize to mantissa between 1-1000, exponent multiple of 3
    return { mantissa: BigDecimal(0), exponent: 0 } if value.zero?

    abs_value = value.abs
    raw_exponent = bigdecimal_log10(abs_value).floor
    engineering_exponent = (raw_exponent / 3.0).floor * 3
    mantissa = abs_value / (BigDecimal(10) ** engineering_exponent)
    mantissa = -mantissa if value.negative?

    { mantissa: mantissa, exponent: engineering_exponent }
  end
end
```

#### CompactFormatter

```ruby
# Compact notation formatter
class CompactFormatter
  include Formatter

  def initialize(locale:, display: :short, **options)
    @base_formatter = FixedDecimalFormatter.new(locale: locale, **options)
    @display = display # :short, :long
    @options = options
  end

  def format(value)
    # Compact notation processing:
    # - Magnitude detection and pattern selection
    # - Value scaling
    # - Unit abbreviation application

    compact_info = find_compact_pattern(value)
    return format_without_compacting(value) unless compact_info

    scaled_value = value / compact_info[:divisor]
    apply_compact_pattern(scaled_value, compact_info)
  end

  private

  def find_compact_pattern(value)
    abs_value = value.abs
    patterns = @base_formatter.formats.compact_patterns(@display, @base_formatter.numbering_system)

    return nil if patterns.empty?

    # Find highest applicable magnitude
    best_magnitude = nil
    magnitudes = patterns.keys.map { |k| Integer(k, 10) }.sort

    magnitudes.each do |magnitude|
      next if abs_value < magnitude
      best_magnitude = magnitude.to_s
    end

    return nil unless best_magnitude

    pattern = @base_formatter.formats.compact_pattern(
      best_magnitude, @display, "other", @base_formatter.numbering_system
    )

    {
      pattern: pattern,
      divisor: find_base_divisor_for_unit(pattern, patterns),
      magnitude: best_magnitude
    }
  end
end
```

### 3. Shared Logic Separation

#### Shared Components
- **Pattern Parsing**: `PatternParser::Number` (unchanged)
- **Value Conversion**: `convert_to_decimal`, special value handling
- **Numbering Systems**: `DigitMapper`, `determine_numbering_system`
- **Basic Formatting**: Integer grouping, decimal point processing
- **CLDR Access**: `NumberFormats` repository (base)

#### Specialized Components
- **Repository Initialization**: `Currencies`, `Units` only when needed
- **Value Transformation**: Currency rounding, percentage multiplication, exponent normalization
- **Pattern Selection**: Style-specific pattern determination logic
- **Token Processing**: Currency symbols, unit symbols, exponent symbols
- **Post-processing**: Unit pattern application, plural form handling

### 4. Unified Interface Design

#### Common Interface Module

```ruby
module Foxtail::Intl::Formatters
  # Common interface for all formatters
  module Formatter
    def format(value)
      raise NotImplementedError, "Subclasses must implement #format"
    end

    def locale
      @locale ||= @base_formatter&.locale
    end

    private

    def determine_plural_category(value = nil)
      # Shared plural category determination logic
      value ||= @original_value
      plural_rules = Foxtail::CLDR::Repository::PluralRules.new(locale)
      plural_rules.select(value)
    end
  end

  # Factory method for backward compatibility
  def self.number_formatter(locale:, **options)
    style = options[:style] || "decimal"
    notation = options[:notation]

    case style
    when "currency"
      CurrencyFormatter.new(locale: locale, **options)
    when "percent"
      PercentFormatter.new(locale: locale, **options)
    when "unit"
      UnitFormatter.new(locale: locale, **options)
    else
      case notation
      when "scientific", "engineering"
        ScientificFormatter.new(locale: locale, notation: notation.to_sym, **options)
      when "compact"
        CompactFormatter.new(locale: locale, **options)
      else
        FixedDecimalFormatter.new(locale: locale, **options)
      end
    end
  end
end
```

#### Direct Usage API

```ruby
# Direct instantiation for specific use cases
currency_formatter = Foxtail::Intl::CurrencyFormatter.new(
  locale: Locale::Tag.parse("en-US"),
  currency: "USD",
  display: :symbol
)
currency_formatter.format(1234.56) # => "$1,234.56"

percent_formatter = Foxtail::Intl::PercentFormatter.new(
  locale: Locale::Tag.parse("en-US")
)
percent_formatter.format(0.1556) # => "15.56%"

unit_formatter = Foxtail::Intl::UnitFormatter.new(
  locale: Locale::Tag.parse("en-US"),
  unit: "meter",
  display: :long
)
unit_formatter.format(1234) # => "1,234 meters"
```

#### Factory Usage API

```ruby
# Factory method for backward compatibility
formatter = Foxtail::Intl::Formatters.number_formatter(
  locale: Locale::Tag.parse("en-US"),
  style: "currency",
  currency: "USD"
)
formatter.format(1234.56) # => "$1,234.56"
```

## Benefits Analysis

### Memory Efficiency
- **Unnecessary Repository Elimination**: Currency formatters don't load `@units`
- **Reduced Initialization Cost**: Only load required data
- **Lighter Instances**: Each specialized formatter has minimal configuration

### Processing Efficiency
- **Reduced Branching**: Eliminates 6 style-based conditional branches
- **Specialized Optimization**: Each formatter optimized for its specific use case
- **Clearer Code Flow**: Each formatter has a focused, understandable responsibility

### Extensibility
- **Easy Addition**: New formatters can be added without affecting existing ones
- **Experimental Features**: Individual formatters can trial new functionality
- **Test Simplicity**: Each component can be tested in isolation

### Maintainability
- **Single Responsibility**: Each formatter has one clear purpose
- **Reduced Complexity**: No more mega-class with multiple responsibilities
- **Clear Boundaries**: Well-defined interfaces between components

## Implementation Strategy

### Phase 1: Foundation
1. Extract `FixedDecimalFormatter` as the base component
2. Move shared utilities to common modules
3. Create the `Formatter` interface module

### Phase 2: Core Formatters
1. Implement `CurrencyFormatter`
2. Implement `PercentFormatter`
3. Implement `UnitFormatter`

### Phase 3: Advanced Formatters
1. Implement `ScientificFormatter`
2. Implement `CompactFormatter`
3. Add factory method for compatibility

### Phase 4: Integration
1. Update existing tests to use new components
2. Performance benchmarking and optimization
3. Documentation and examples

## Considerations

### Performance Impact
- **Positive**: Reduced memory usage, fewer conditional branches
- **Neutral**: Object creation overhead should be minimal
- **Monitoring**: Benchmark before/after to ensure no regression

### API Compatibility
- **Factory Method**: Maintains existing `NumberFormat.new` behavior
- **Direct Access**: Provides more efficient specialized access
- **Migration Path**: Gradual adoption possible

### Code Organization
- Each formatter in separate file under `lib/foxtail/intl/formatters/`
- Shared utilities in `lib/foxtail/intl/formatters/shared/`
- Factory and interface in `lib/foxtail/intl/formatters.rb`

This modular design provides a cleaner, more maintainable architecture while preserving all existing functionality and performance characteristics.