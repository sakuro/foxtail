### Game messages for French

## Custom Functions
#
# ARTICLE_ITEM($item, $count, type, cap)
#   Returns article + item name with gender agreement and elision.
#   - type: "indefinite" (un/une), "definite" (le/la/l'), "none" (default: "indefinite")
#   Example: { ARTICLE_ITEM("sword", type: "definite") } → "l'épée" (elision)
#   Example: { ARTICLE_ITEM("axe", type: "definite") } → "la hache" (h aspiré, no elision)
#   Example: { ARTICLE_ITEM("dagger", type: "indefinite") } → "un poignard"
#
# COUNT_ITEM($item, $count, type, cap)
#   Returns count + item, using counters when available.
#   Counter elision is handled automatically (fiole de potion vs fiole d'élixir).
#   - type: "indefinite", "definite", or "none" (default: "none")
#   Example: { COUNT_ITEM("sword", 3) } → "3 épées"
#   Example: { COUNT_ITEM("healing-potion", 1, type: "indefinite") } → "une fiole de potion de soin"
#   Example: { COUNT_ITEM("elixir", 1, type: "indefinite") } → "une fiole d'élixir"
#
# French elision notes:
#   - Definite articles le/la become l' before vowels (l'épée)
#   - Exception: h aspiré words keep la/le (la hache)
#   - Counter "de" becomes "d'" before vowels (fiole d'élixir)

## Messages

# Finding items (counter-aware)
found-item =
    { $count ->
        [one] Tu as trouvé { COUNT_ITEM($item, $count, type: "indefinite") }.
       *[other] Tu as trouvé { COUNT_ITEM($item, $count) }.
    }

# Item is here (sentence start - capitalize, counter-aware)
item-is-here =
    { $count ->
        [one] { COUNT_ITEM($item, $count, type: "definite", cap: "true") } est ici.
       *[other] { COUNT_ITEM($item, $count, cap: "true") } sont ici.
    }

# Attack with item (count defaults to 1)
attack-with-item = Tu attaques avec { ARTICLE_ITEM($item, type: "definite") }.

# Drop item (counter-aware)
drop-item =
    { $count ->
        [one] Tu as laissé tomber { COUNT_ITEM($item, $count, type: "indefinite") }.
       *[other] Tu as laissé tomber { COUNT_ITEM($item, $count) }.
    }

# Inventory (counter-aware)
inventory-item =
    { $count ->
        [one] { COUNT_ITEM($item, $count, type: "indefinite") }
       *[other] { COUNT_ITEM($item, $count) }
    }
