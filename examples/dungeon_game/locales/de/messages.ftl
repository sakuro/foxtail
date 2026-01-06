### Game messages for German

## Custom Functions
#
# ARTICLE_ITEM($item, $count, type, case, cap)
#   Returns article + item name with gender/case agreement.
#   - type: "indefinite" (ein/eine), "definite" (der/die/das), "none" (default: "indefinite")
#   Example: { ARTICLE_ITEM("sword", type: "definite", case: "dative") } → "dem Schwert"
#   Example: { ARTICLE_ITEM("axe", type: "indefinite", case: "accusative") } → "eine Axt"
#
# COUNT_ITEM($item, $count, type, case, cap)
#   Returns count + item, using counters when available.
#   - type: "indefinite", "definite", or "none" (default: "none")
#   Example: { COUNT_ITEM("sword", 3, case: "accusative") } → "3 Schwerter"
#   Example: { COUNT_ITEM("gauntlet", 1, type: "indefinite") } → "ein Paar Panzerhandschuhe"
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
        [one] Du hast { COUNT_ITEM($item, $count, type: "indefinite", case: "accusative") } gefunden.
       *[other] Du hast { COUNT_ITEM($item, $count, case: "accusative") } gefunden.
    }

# Item is here (nominative case - subject, sentence start - capitalize, counter-aware)
item-is-here =
    { $count ->
        [one] { COUNT_ITEM($item, $count, type: "definite", case: "nominative", cap: "true") } ist hier.
       *[other] { COUNT_ITEM($item, $count, case: "nominative", cap: "true") } sind hier.
    }

# Attack with item (dative case - with preposition "mit", count defaults to 1)
attack-with-item = Du greifst mit { ARTICLE_ITEM($item, type: "definite", case: "dative") } an.

# Drop item (accusative case - direct object, counter-aware)
drop-item =
    { $count ->
        [one] Du hast { COUNT_ITEM($item, $count, type: "indefinite", case: "accusative") } fallen gelassen.
       *[other] Du hast { COUNT_ITEM($item, $count, case: "accusative") } fallen gelassen.
    }

# Inventory (nominative case, counter-aware)
inventory-item =
    { $count ->
        [one] { COUNT_ITEM($item, $count, type: "indefinite", case: "nominative") }
       *[other] { COUNT_ITEM($item, $count, case: "nominative") }
    }

