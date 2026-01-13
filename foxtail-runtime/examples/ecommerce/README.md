# E-commerce Example

Demonstrates e-commerce localization with currency, stock counts, and cart messages.

## Features

- Currency formatting with `NUMBER($price, style: "currency", currency: "...")`
- Percent formatting for discounts with `NUMBER($percent, style: "percent")`
- Plurals for stock counts and cart items
- Loading FTL files from disk with `Resource.from_file`

## Structure

```
ecommerce/
  main.rb           # Main application code
  locales/
    en.ftl          # English translations (USD)
    ja.ftl          # Japanese translations (JPY)
```

## Run

```bash
bundle exec ruby foxtail-runtime/examples/ecommerce/main.rb
```

## Key Concepts

### Currency Formatting

Different currencies are formatted appropriately for each locale:

```ftl
# en.ftl - US Dollars
product-price = { NUMBER($price, style: "currency", currency: "USD") }

# ja.ftl - Japanese Yen
product-price = { NUMBER($price, style: "currency", currency: "JPY") }
```

Output:
- English: `$149.99`
- Japanese: `¥22,000`

### Plural Forms

Stock and cart counts use locale-appropriate plural forms:

```ftl
# en.ftl - English has singular/plural distinction
stock-status =
    { $count ->
        [0] Out of stock
        [one] Only { $count } left in stock!
       *[other] { $count } items in stock
    }

# ja.ftl - Japanese doesn't distinguish singular/plural
stock-status =
    { $count ->
        [0] 在庫切れ
        [one] 残り{ $count }点のみ！
       *[other] 在庫{ $count }点
    }
```

### Discount Percentages

Percent formatting works across locales:

```ftl
product-discount = { NUMBER($percent, style: "percent") } off
```

With `percent: 0.2`:
- English: `20% off`
- Japanese: `20%オフ`
