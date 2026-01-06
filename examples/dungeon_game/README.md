# Dungeon Game Example

Demonstrates advanced localization for game items with grammatical gender, number, case, articles, and counter words.

## Features

- **Two-layer Bundle architecture**: Separate bundles for items (Terms) and messages
- **Custom functions**: Language-specific functions for dynamic item embedding
  - English/German/French: `ARTICLE_ITEM`, `COUNT_ITEM`
  - Japanese: `ITEM`, `COUNT`
- **German grammatical cases**: nominative, accusative, dative, genitive
- **German grammatical gender**: masculine, feminine, neuter
- **French elision**: Automatic article contraction (le/la → l' before vowels)
- **Counter words**: Japanese 助数詞 (振, 本, 組, 瓶), English/German/French counters (pair, flask, Paar, Flasche, paire, fiole)
- **FTL-based article definitions**: Articles defined in FTL, not hardcoded in Ruby

## Structure

```
dungeon_game/
  main.rb                    # Main application
  functions/
    base.rb                  # Base class for item functions
    de.rb                    # German-specific (case declension)
    en.rb                    # English-specific (a/an selection)
    fr.rb                    # French-specific (elision handling)
    ja.rb                    # Japanese-specific (counter words)
  locales/
    en/
      articles.ftl           # English article terms (-def-article, -indef-article)
      counters.ftl           # English counter terms (-pair, -flask)
      items.ftl              # English item terms (singular/plural, counter refs)
      messages.ftl           # English messages
    de/
      articles.ftl           # German article terms (gender × case × number)
      counters.ftl           # German counter terms (Paar, Flasche)
      items.ftl              # German item terms (gender, case, number)
      messages.ftl           # German messages with case usage
    fr/
      articles.ftl           # French article terms with elision patterns
      counters.ftl           # French counter terms (paire, fiole)
      items.ftl              # French item terms (gender, elision flags)
      messages.ftl           # French messages
    ja/
      items.ftl              # Japanese item terms with counters
      messages.ftl           # Japanese messages
```

## Run

```bash
bundle exec ruby examples/dungeon_game/main.rb
```

## Architecture

### Two-layer Bundle Design

```
┌─────────────────────────────────────────────────┐
│  Items Bundle (per language)                    │
│  - Terms: items, articles, counters             │
│  - All linguistic data in FTL                   │
└─────────────────────────────────────────────────┘
                      ↓ Captured via closure
┌─────────────────────────────────────────────────┐
│  Custom Functions (ItemFunctions module)        │
│  - Language-specific subclasses                 │
│  - Resolves terms and formats output            │
└─────────────────────────────────────────────────┘
                      ↓ Injected into functions:
┌─────────────────────────────────────────────────┐
│  Messages Bundle (per language)                 │
│  - Messages only                                │
│  - Uses custom functions to embed item names    │
└─────────────────────────────────────────────────┘
```

### Why Two Bundles?

1. **Separation of concerns**: Item vocabulary vs. game messages
2. **Translator efficiency**: Edit item declensions directly in FTL
3. **No circular references**: Items Bundle created first, then used by functions
4. **Reusability**: Items Bundle can be shared across multiple Messages Bundles

## Key Concepts

### Function Signatures

Each language provides different functions based on its needs:

**English/German/French:**
```ftl
# ARTICLE_ITEM: Item with article
{ ARTICLE_ITEM($item, $count, type: "indefinite", case: "nominative", cap: "false") }

# COUNT_ITEM: Count with item (uses counter if defined)
{ COUNT_ITEM($item, $count, type: "none", case: "nominative", cap: "false") }
```

**Japanese:**
```ftl
# ITEM: Just the item name
{ ITEM($item) }

# COUNT: Count with counter word
{ COUNT($item, $count) }
```

### German Article Declension (FTL-based)

Articles are defined as FTL terms with gender, count, and case selectors:

```ftl
-def-article =
    { $gender ->
        [masculine]
            { $count ->
                [one]
                    { $case ->
                       *[nominative] der
                        [accusative] den
                        [dative] dem
                        [genitive] des
                    }
               *[other]
                    { $case ->
                       *[nominative] die
                        ...
                    }
            }
        ...
    }
```

### German Items with Cases

```ftl
-dagger =
    { $count ->
        [one]
            { $case ->
               *[nominative] Dolch
                [accusative] Dolch
                [dative] Dolch
                [genitive] Dolches
            }
       *[other]
            { $case ->
               *[nominative] Dolche
                [accusative] Dolche
                [dative] Dolchen
                [genitive] Dolche
            }
    }
    .gender = masculine
```

### French Elision

French handles elision (l'épée instead of la épée) via:

1. **Automatic detection**: NFD normalization to detect vowels (é → e)
2. **Explicit override**: `.elision = false` for h aspiré words (la hache)
3. **FTL format patterns**: Conditional spacing based on elision

```ftl
# Format pattern for article + item
-fmt-article-item =
    { $elision ->
        [true] {$article}{$item}
       *[false] {$article} {$item}
    }

# Item with h aspiré (no elision)
-axe = hache
    .gender = feminine
    .elision = false
```

### Japanese Counter Words

Items can specify a counter term:

```ftl
-sword = 剣
    .counter = -counter-furi

-counter-furi =
    { $count ->
        [1] 1振り
        [2] 2振り
        [3] 3振り
       *[other] { $count }振り
    }
```

## Output Examples

### English

```
You found a dagger.
You found 3 daggers.
You found a pair of gauntlets.
You found 3 pairs of gauntlets.
You found a flask of elixir.
You attack with the sword.
```

### German

```
Du hast einen Dolch gefunden.      # accusative, indefinite, masculine
Du hast 3 Dolche gefunden.         # accusative, plural
Du hast ein Paar Panzerhandschuhe gefunden.  # counter: Paar
Du greifst mit dem Schwert an.     # dative, definite, neuter
```

### French

```
Tu as trouvé un poignard.          # masculine, indefinite
Tu as trouvé une épée.             # feminine, indefinite
L'épée est ici.                    # elision: l' before vowel
La hache est ici.                  # h aspiré: no elision
Tu as trouvé une fiole d'élixir.   # counter elision: d' before vowel
```

### Japanese

```
短剣を1本見つけた。                 # counter: 本
剣を3振り見つけた。                 # counter: 振り
籠手を1組見つけた。                 # counter: 組
```

## Adding New Items

1. Add a term to each language's `items.ftl`
2. Include required attributes (.gender, .counter, .elision as needed)

```ftl
# de/items.ftl
-spear =
    { $count ->
        [one]
            { $case ->
               *[nominative] Speer
                [accusative] Speer
                [dative] Speer
                [genitive] Speers
            }
       *[other]
            { $case ->
               *[nominative] Speere
                ...
            }
    }
    .gender = masculine
```

No changes needed to Ruby code or message FTL files.
