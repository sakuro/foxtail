# CLDR Numbering Systems Analysis

This document summarizes the Unicode CLDR (Common Locale Data Repository) numbering systems data found in the downloaded CLDR v46 core data.

## Overview

The CLDR provides comprehensive numbering system data for internationalization, including:
- 96 different numbering systems
- Locale-specific default numbering systems
- Native and traditional numbering system mappings
- Number formatting patterns

## Numbering System Types

### 1. Numeric Systems
Positional numbering systems using specific digit characters:

| System ID | Description | Digits |
|-----------|-------------|---------|
| `latn` | Latin digits | 0123456789 |
| `arab` | Arabic-Indic digits | ٠١٢٣٤٥٦٧٨٩ |
| `arabext` | Extended Arabic-Indic | ۰۱۲۳۴۵۶۷۸۹ |
| `deva` | Devanagari digits | ०१२३४५६७८९ |
| `beng` | Bengali digits | ০১২৩৪৫৬৭৮৯ |
| `gujr` | Gujarati digits | ૦૧૨૩૪૫૬૭૮૯ |
| `telu` | Telugu digits | ౦౧౨౩౪౫౬౭౮౯ |
| `thai` | Thai digits | ๐๑๒๓๔๕๖๗๘๙ |
| `fullwide` | Full-width digits | ０１２３４５６７８９ |
| `hanidec` | Chinese decimal | 〇一二三四五六七八九 |

### 2. Algorithmic Systems
Rule-based numbering systems:

| System ID | Description | Rules |
|-----------|-------------|-------|
| `jpan` | Japanese numerals | ja/SpelloutRules/spellout-cardinal |
| `jpanfin` | Japanese financial | ja/SpelloutRules/spellout-cardinal-financial |
| `hans` | Simplified Chinese | zh/SpelloutRules/spellout-cardinal |
| `hant` | Traditional Chinese | zh_Hant/SpelloutRules/spellout-cardinal |
| `roman` | Roman numerals | roman-upper |
| `romanlow` | Roman lowercase | roman-lower |
| `armn` | Armenian upper | armenian-upper |
| `hebr` | Hebrew numerals | hebrew |
| `grek` | Greek upper | greek-upper |
| `ethi` | Ethiopic numerals | ethiopic |

## Locale-Specific Configurations

### Default Numbering Systems
89 locales explicitly define their default numbering system. Most use `latn` (Latin digits), but some specify regional defaults:

```xml
<!-- Arabic locales -->
<defaultNumberingSystem>latn</defaultNumberingSystem>
<defaultNumberingSystem alt="latn">latn</defaultNumberingSystem>
```

### Native Numbering Systems
Regional traditional numbering systems:

| Locale | Native System | Digits/Type |
|--------|---------------|-------------|
| Arabic (`ar`) | `arab` | ٠١٢٣٤٥٦٧٨٩ |
| Hindi (`hi`) | `deva` | ०१२३४५६७८९ |
| Bengali (`bn`) | `beng` | ০১২৩৪৫৬৭৮৯ |
| Gujarati (`gu`) | `gujr` | ૦૧૨૩૪૫૬૭૮૯ |
| Telugu (`te`) | `telu` | ౦౧౨౩౪౫౬౭౮౯ |
| Chinese (`zh`) | `hanidec` | 〇一二三四五六七八九 |
| Urdu (`ur`) | `arabext` | ۰۱۲۳۴۵۶۷۸۹ |

### Traditional Numbering Systems
Ceremonial or formal numbering systems:

| Locale | Traditional System | Type |
|--------|-------------------|------|
| Japanese (`ja`) | `jpan` | Algorithmic (一、二、三...) |
| Chinese Simplified (`zh`) | `hans` | Algorithmic |
| Chinese Traditional (`zh_Hant`) | `hant` | Algorithmic |
| Greek (`el`) | `grek` | Algorithmic (Α, Β, Γ...) |
| Hebrew (`he`) | `hebr` | Algorithmic (א, ב, ג...) |
| Armenian (`hy`) | `armn` | Algorithmic |
| Georgian (`ka`) | `geor` | Algorithmic |
| Tamil (`ta`) | `taml` | Algorithmic |

## Special Features

### Financial Numbering
Special numbering systems for financial contexts:
- `jpanfin`: Japanese financial numerals (壱、弐、参...)
- `hansfin`: Chinese simplified financial numerals
- `hantfin`: Chinese traditional financial numerals

### Mathematical Numbering
Unicode mathematical alphanumeric symbols:
- `mathbold`: Mathematical bold digits
- `mathdbl`: Mathematical double-struck digits
- `mathmono`: Mathematical monospace digits
- `mathsans`: Mathematical sans-serif digits

### Legacy and Specialized
- `segment`: Legacy computing segmented digits
- `outlined`: Legacy computing outlined digits
- Various script-specific systems (Brahmi, Chakma, Limbu, etc.)

## Format Patterns by Locale

### Japanese Number Formatting
```xml
<decimalFormats numberSystem="latn">
  <decimalFormatLength type="short">
    <pattern type="10000" count="other">0万</pattern>
    <pattern type="100000000" count="other">0億</pattern>
    <pattern type="1000000000000" count="other">0兆</pattern>
  </decimalFormatLength>
</decimalFormats>
```

### Hindi Number Formatting
```xml
<decimalFormats numberSystem="latn">
  <pattern>#,##,##0.###</pattern> <!-- Indian numbering grouping -->
  <pattern type="100000" count="other">0 लाख</pattern>
  <pattern type="10000000" count="other">0 करोड़</pattern>
</decimalFormats>
```

## Implementation Considerations for Foxtail

### 1. Numbering System Selection
- Default: Use locale's default numbering system
- Native: Use `<native>` tag value when available
- Traditional: Use `<traditional>` tag for formal contexts
- Override: Allow explicit numbering system specification

### 2. CLDR Integration
- Extract numbering system definitions from `numberingSystems.xml`
- Parse locale-specific configurations from main locale files
- Support both numeric and algorithmic numbering systems

### 3. API Design
```ruby
# Example API for Foxtail
bundle = Foxtail::Bundle.new(ICU4X::Locale.parse("ja"))
bundle.format("price", amount: 1234, numbering_system: "jpan")
# => "一千二百三十四円"

bundle.format("price", amount: 1234, numbering_system: "latn")
# => "1,234円"
```

### 4. Performance Optimization
- Cache compiled numbering system rules
- Precompute digit mappings for numeric systems
- Lazy load algorithmic rules only when needed

## Data Sources

- **Primary**: `/tmp/cldr-core-v46/common/supplemental/numberingSystems.xml`
- **Locale data**: `/tmp/cldr-core-v46/common/main/*.xml`
- **BCP47 tags**: `/tmp/cldr-core-v46/common/bcp47/number.xml`
- **Test cases**: `/tmp/cldr-core-v46/common/testData/messageFormat/tests/functions/number.json`

## References

- [Unicode CLDR v46](http://unicode.org/Public/cldr/46/)
- [LDML Specification](http://unicode.org/reports/tr35/)
- [Unicode License v3](https://opensource.org/license/unicode-license-v3)