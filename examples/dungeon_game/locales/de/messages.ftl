### Game messages for German

## Custom Functions
#
# ITEM($item, $count, type, case, cap)
#   Returns article + item name with gender/case agreement.
#   - type: "indefinite" (ein/eine), "definite" (der/die/das), "none" (default: "indefinite")
#   Example: { ITEM("sword", type: "definite", case: "dative") } → "dem Schwert"
#   Example: { ITEM("axe", type: "indefinite", case: "accusative") } → "eine Axt"
#
# ITEM_WITH_COUNT($item, $count, type, case, cap)
#   Returns count + item, using counters when available.
#   - type: "indefinite", "definite", or "none" (default: "none")
#   Example: { ITEM_WITH_COUNT("sword", 3, case: "accusative") } → "3 Schwerter"
#   Example: { ITEM_WITH_COUNT("gauntlet", 1, type: "indefinite") } → "ein Paar Panzerhandschuhe"
#
# German grammatical cases:
#   - nominative: Subject of the sentence (Der Dolch ist hier.)
#   - accusative: Direct object (Du hast einen Dolch gefunden.)
#   - dative: Indirect object / with prepositions (Du greifst mit dem Schwert an.)
#   - genitive: Possession (rarely used in this example)

## Messages

# Finding items (accusative case - direct object, counter-aware)
found-item =
    { $count ->
        [one] Du hast { ITEM_WITH_COUNT($item, $count, type: "indefinite", case: "accusative") } gefunden.
       *[other] Du hast { ITEM_WITH_COUNT($item, $count, case: "accusative") } gefunden.
    }

# Item is here (nominative case - subject, sentence start - capitalize, counter-aware)
item-is-here =
    { $count ->
        [one] { ITEM_WITH_COUNT($item, $count, type: "definite", case: "nominative", cap: "true") } ist hier.
       *[other] { ITEM_WITH_COUNT($item, $count, case: "nominative", cap: "true") } sind hier.
    }

# Attack with item (dative case - with preposition "mit", count defaults to 1)
attack-with-item = Du greifst mit { ITEM($item, type: "definite", case: "dative") } an.

# Drop item (accusative case - direct object, counter-aware)
drop-item =
    { $count ->
        [one] Du hast { ITEM_WITH_COUNT($item, $count, type: "indefinite", case: "accusative") } fallen gelassen.
       *[other] Du hast { ITEM_WITH_COUNT($item, $count, case: "accusative") } fallen gelassen.
    }

# Inventory (nominative case, counter-aware)
inventory-item =
    { $count ->
        [one] { ITEM_WITH_COUNT($item, $count, type: "indefinite", case: "nominative") }
       *[other] { ITEM_WITH_COUNT($item, $count, case: "nominative") }
    }

