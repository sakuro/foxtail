# Node.js Numbering Systems Usage

This document outlines how Node.js leverages numbering systems through the `Intl.NumberFormat` API, providing insights for Foxtail's implementation.

## Overview

Node.js provides comprehensive internationalization support through the ECMAScript Internationalization API, specifically `Intl.NumberFormat`, which supports various numbering systems defined by Unicode CLDR.

## Basic Usage Patterns

### 1. Default Locale-based Numbering

```javascript
const number = 123456.789;

// Arabic with Arabic-Indic digits
console.log(new Intl.NumberFormat("ar-EG").format(number));
// Output: ١٢٣٤٥٦٫٧٨٩

// Hindi with Latin digits (default)
console.log(new Intl.NumberFormat("hi-IN").format(number));
// Output: 1,23,456.789

// German with European formatting
console.log(new Intl.NumberFormat("de-DE").format(number));
// Output: 123.456,789
```

### 2. Explicit Numbering System Selection

#### Using Unicode Extension (-u-nu)
```javascript
const number = 123456.789;

// Chinese decimal numbering
console.log(new Intl.NumberFormat("zh-Hans-CN-u-nu-hanidec").format(number));
// Output: 一二三,四五六.七八九

// Arabic numbering on English locale
console.log(new Intl.NumberFormat("en-US-u-nu-arab").format(number));
// Output: ١٢٣٤٥٦٫٧٨٩

// Devanagari numbering
console.log(new Intl.NumberFormat("en-US-u-nu-deva").format(number));
// Output: १२३४५६.७८९

// Thai numbering
console.log(new Intl.NumberFormat("en-US-u-nu-thai").format(number));
// Output: ๑๒๓๔๕๖.๗๘๙
```

#### Using Constructor Options
```javascript
// Alternative syntax using options object
const arabFormatter = new Intl.NumberFormat("en-US", {
  numberingSystem: "arab"
});

const devaFormatter = new Intl.NumberFormat("en-US", {
  numberingSystem: "deva"
});

const hanidecFormatter = new Intl.NumberFormat("en-US", {
  numberingSystem: "hanidec"
});

console.log(arabFormatter.format(12345));     // ١٢٣٤٥
console.log(devaFormatter.format(12345));     // १२३४५
console.log(hanidecFormatter.format(12345));  // 一二三四五
```

## Comprehensive Numbering System Examples

### Asian Numbering Systems

```javascript
const num = 98765;

// Chinese traditional
console.log(new Intl.NumberFormat("zh-Hant-u-nu-hanidec").format(num));
// Output: 九八七六五

// Japanese full-width
console.log(new Intl.NumberFormat("ja-JP-u-nu-fullwide").format(num));
// Output: ９８７６５

// Korean with Latin (default)
console.log(new Intl.NumberFormat("ko-KR").format(num));
// Output: 98,765
```

### Indian Subcontinent Systems

```javascript
const num = 1234567;

// Bengali numbering
console.log(new Intl.NumberFormat("bn-BD-u-nu-beng").format(num));
// Output: ১২,৩৪,৫৬৭

// Gujarati numbering
console.log(new Intl.NumberFormat("gu-IN-u-nu-gujr").format(num));
// Output: ૧૨,૩૪,૫૬૭

// Telugu numbering
console.log(new Intl.NumberFormat("te-IN-u-nu-telu").format(num));
// Output: ౧౨,౩౪,౫౬౭

// Tamil decimal
console.log(new Intl.NumberFormat("ta-IN-u-nu-tamldec").format(num));
// Output: ௧௨,௩௪,௫௬௭
```

### Southeast Asian Systems

```javascript
const num = 42000;

// Thai numbering
console.log(new Intl.NumberFormat("th-TH-u-nu-thai").format(num));
// Output: ๔๒,๐๐๐

// Myanmar numbering
console.log(new Intl.NumberFormat("my-MM-u-nu-mymr").format(num));
// Output: ၄၂,၀၀၀

// Khmer numbering
console.log(new Intl.NumberFormat("km-KH-u-nu-khmr").format(num));
// Output: ៤២,០០០

// Lao numbering
console.log(new Intl.NumberFormat("lo-LA-u-nu-laoo").format(num));
// Output: ໔໒,໐໐໐
```

## Currency Formatting with Numbering Systems

```javascript
const price = 1234.56;

// Arabic currency with Arabic digits
console.log(new Intl.NumberFormat("ar-SA-u-nu-arab", {
  style: "currency",
  currency: "SAR"
}).format(price));
// Output: ١٬٢٣٤٫٥٦ ر.س.‏

// Indian currency with Devanagari digits
console.log(new Intl.NumberFormat("hi-IN-u-nu-deva", {
  style: "currency",
  currency: "INR"
}).format(price));
// Output: ₹१,२३४.५६

// Japanese currency with full-width digits
console.log(new Intl.NumberFormat("ja-JP-u-nu-fullwide", {
  style: "currency",
  currency: "JPY"
}).format(price));
// Output: ￥１，２３５
```

## Percentage Formatting

```javascript
const ratio = 0.1234;

// Arabic percentage
console.log(new Intl.NumberFormat("ar-EG-u-nu-arab", {
  style: "percent"
}).format(ratio));
// Output: ١٢٪

// Thai percentage
console.log(new Intl.NumberFormat("th-TH-u-nu-thai", {
  style: "percent"
}).format(ratio));
// Output: ๑๒%
```

## Advanced Features

### Discovering Available Numbering Systems

```javascript
// Get supported numbering systems
const supportedNumberingSystems = Intl.supportedValuesOf('numberingSystem');
console.log(supportedNumberingSystems);
// Output: ['adlm', 'ahom', 'arab', 'arabext', 'bali', 'beng', 'bhks', ...]

// Get numbering systems for a specific locale
const locale = new Intl.Locale("hi-IN");
console.log(locale.getNumberingSystems());
// Output: ['latn'] (default for Hindi in India)

const arabicLocale = new Intl.Locale("ar-SA");
console.log(arabicLocale.getNumberingSystems());
// Output: ['arab', 'latn']
```

### Inspecting Resolved Options

```javascript
const formatter = new Intl.NumberFormat("zh-CN-u-nu-hanidec");
console.log(formatter.resolvedOptions());
// Output: {
//   locale: "zh-CN",
//   numberingSystem: "hanidec",
//   style: "decimal",
//   minimumIntegerDigits: 1,
//   ...
// }
```

### Mathematical Numbering Systems

```javascript
const num = 123;

// Mathematical bold
console.log(new Intl.NumberFormat("en-US-u-nu-mathbold").format(num));
// Output: 𝟏𝟐𝟑

// Mathematical monospace
console.log(new Intl.NumberFormat("en-US-u-nu-mathmono").format(num));
// Output: 𝟷𝟸𝟹

// Mathematical double-struck
console.log(new Intl.NumberFormat("en-US-u-nu-mathdbl").format(num));
// Output: 𝟙𝟚𝟛
```

## Node.js Specific Considerations

### ICU Data Requirements

Node.js builds with different ICU (International Components for Unicode) data sets:

```bash
# Check ICU version and data
node -p "process.versions.icu"

# Small ICU (English only)
node --icu-data-dir=node_modules/full-icu app.js

# Or install full-icu package
npm install full-icu
```

### Performance Optimization

```javascript
// Cache formatters for better performance
const formatters = new Map();

function getFormatter(locale, options) {
  const key = `${locale}:${JSON.stringify(options)}`;
  if (!formatters.has(key)) {
    formatters.set(key, new Intl.NumberFormat(locale, options));
  }
  return formatters.get(key);
}

// Usage
const arabFormatter = getFormatter("ar-SA-u-nu-arab", { style: "currency", currency: "SAR" });
console.log(arabFormatter.format(1234.56));
```

### Error Handling

```javascript
function formatNumber(number, locale, numberingSystem) {
  try {
    const formatter = new Intl.NumberFormat(`${locale}-u-nu-${numberingSystem}`);
    return formatter.format(number);
  } catch (error) {
    // Fallback to basic locale
    console.warn(`Numbering system ${numberingSystem} not supported, falling back to default`);
    return new Intl.NumberFormat(locale).format(number);
  }
}

console.log(formatNumber(123, "en-US", "invalid")); // Falls back to Latin
```

## Compatibility with Foxtail

### API Mapping

The Node.js patterns can inform Foxtail's Ruby API design:

```ruby
# Foxtail equivalent concepts
bundle = Foxtail::Bundle.new(Locale::Tag.parse("ar-SA"))
bundle.format("price", amount: 1234.56, numbering_system: "arab")

# With number format options
bundle.format("percentage",
  value: 0.1234,
  style: "percent",
  numbering_system: "arab"
)
```

### Performance Lessons

1. **Cache compiled formatters** - Node.js benefits from caching `Intl.NumberFormat` instances
2. **Lazy loading** - Only load numbering system data when needed
3. **Fallback strategies** - Graceful degradation when numbering systems aren't available
4. **Validation** - Check numbering system support before usage

## References

- [MDN Intl.NumberFormat](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl/NumberFormat)
- [MDN Intl.Locale](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl/Locale)
- [Unicode LDML Specification](http://unicode.org/reports/tr35/)
- [Node.js ICU Documentation](https://nodejs.org/api/intl.html)