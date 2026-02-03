# Dungeon Game Example

Demonstrates advanced localization for game items with grammatical gender, number, case, articles, and counter words.

## Features

- **Custom functions**: Language-specific functions for dynamic item embedding
  - All languages: `ITEM`, `ITEM_WITH_COUNT`
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
    item.rb                  # Item Value type
    item_with_count.rb       # ItemWithCount Value type
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

```
┌─────────────────────────────────────────────────┐
│  Bundle (per locale)                            │
│  - Terms: items, articles, counters             │
│  - Messages                                     │
│  - All linguistic data in FTL                   │
└─────────────────────────────────────────────────┘
                      ↓ Registered as functions
┌─────────────────────────────────────────────────┐
│  Custom Functions (ItemFunctions module)        │
│  - Language-specific subclasses                 │
│  - Returns Value objects for deferred formatting│
│  - Resolves terms and formats output            │
└─────────────────────────────────────────────────┘
```

## Key Concepts

### Function Signatures

All languages provide `ITEM` and `ITEM_WITH_COUNT` functions:

**English/German/French:**
```ftl
# ITEM: Item with article
{ ITEM($item, $count, type: "indefinite", case: "nominative", cap: "false") }

# ITEM_WITH_COUNT: Count with item (uses counter if defined)
{ ITEM_WITH_COUNT($item, $count, type: "none", case: "nominative", cap: "false") }
```

**Japanese:**
```ftl
# ITEM: Item name
{ ITEM($item) }

# ITEM_WITH_COUNT: Count + counter + item (e.g., "3振の剣")
{ ITEM_WITH_COUNT($item, $count) }
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
2. **H muet override**: `.elision = true` for silent-h words (l'herbe)
3. **FTL format patterns**: Conditional spacing based on elision

Note: H aspiré words like "hache" don't need any override since "h" is not a vowel.

```ftl
# Format pattern for article + item
-fmt-article-item =
    { $elision ->
        [true] {$article}{$item}
       *[false] {$article} {$item}
    }

# Item with h muet (elision required)
-herb = herbe
    .gender = feminine
    .elision = true

# Item with h aspiré (no elision by default - h is not a vowel)
-axe = hache
    .gender = feminine
```

### Japanese Counter Words

Items specify a counter word (助数詞) via the `.counter` attribute:

```ftl
-sword = 剣
    .counter = 振

-herb = 薬草
    .counter = 束

-gauntlet = 籠手
    .counter = 組

-elixir = 霊薬
    .counter = 瓶
```

The `ITEM_WITH_COUNT` function formats as: `<count><counter>の<item>` (e.g., `3振の剣`, `1組の籠手`, `5瓶の霊薬`)

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
1振の短剣を見つけた。               # counter: 振
3振の剣を見つけた。                 # counter: 振
1組の籠手を見つけた。               # counter: 組
5瓶の回復薬を見つけた。             # counter: 瓶
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
