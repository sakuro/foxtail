### Game messages for French

## Custom Functions
#
# ITEM($item, $count, type, cap)
#   Returns article + item name with gender agreement and elision.
#   - type: "indefinite" (un/une), "definite" (le/la/l'), "none" (default: "indefinite")
#   Example: { ITEM("sword", type: "definite") } → "l'épée" (elision)
#   Example: { ITEM("axe", type: "definite") } → "la hache" (h aspiré, no elision)
#   Example: { ITEM("dagger", type: "indefinite") } → "un poignard"
#
# ITEM_WITH_COUNT($item, $count, type, cap)
#   Returns count + item, using counters when available.
#   Counter elision is handled automatically (fiole de potion vs fiole d'élixir).
#   - type: "indefinite", "definite", or "none" (default: "none")
#   Example: { ITEM_WITH_COUNT("sword", 3) } → "3 épées"
#   Example: { ITEM_WITH_COUNT("healing-potion", 1, type: "indefinite") } → "une fiole de potion de soin"
#   Example: { ITEM_WITH_COUNT("elixir", 1, type: "indefinite") } → "une fiole d'élixir"
#
# French elision notes:
#   - Definite articles le/la become l' before vowels (l'épée)
#   - h muet (silent h): elision occurs, requires .elision = true (l'herbe)
#   - h aspiré (aspirated h): no elision, no override needed (la hache)
#   - Counter "de" becomes "d'" before vowels (fiole d'élixir)

## Messages

# Finding items (counter-aware)
found-item =
    { $count ->
        [one] Tu as trouvé { ITEM_WITH_COUNT($item, $count, type: "indefinite") }.
       *[other] Tu as trouvé { ITEM_WITH_COUNT($item, $count) }.
    }

# Item is here (sentence start - capitalize, counter-aware)
item-is-here =
    { $count ->
        [one] { ITEM_WITH_COUNT($item, $count, type: "definite", cap: "true") } est ici.
       *[other] { ITEM_WITH_COUNT($item, $count, cap: "true") } sont ici.
    }

# Attack with item (count defaults to 1)
attack-with-item = Tu attaques avec { ITEM($item, type: "definite") }.

# Drop item (counter-aware)
drop-item =
    { $count ->
        [one] Tu as laissé tomber { ITEM_WITH_COUNT($item, $count, type: "indefinite") }.
       *[other] Tu as laissé tomber { ITEM_WITH_COUNT($item, $count) }.
    }

# Inventory (counter-aware)
inventory-item =
    { $count ->
        [one] { ITEM_WITH_COUNT($item, $count, type: "indefinite") }
       *[other] { ITEM_WITH_COUNT($item, $count) }
    }
