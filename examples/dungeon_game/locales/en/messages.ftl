### Game messages for English

## Custom Functions
#
# ARTICLE_ITEM($item, $count, type, cap)
#   Returns article + item name.
#   - type: "indefinite" (a/an), "definite" (the), or "none" (default: "indefinite")
#   Example: { ARTICLE_ITEM("axe", type: "indefinite") } → "an axe"
#   Example: { ARTICLE_ITEM("sword", type: "definite") } → "the sword"
#
# COUNT_ITEM($item, $count, type, cap)
#   Returns count + item, using counters when available.
#   For items with counters (e.g., gauntlet → pair), uses counter-based format.
#   - type: "indefinite", "definite", or "none" (default: "none")
#   Example: { COUNT_ITEM("sword", 3) } → "3 swords"
#   Example: { COUNT_ITEM("gauntlet", 1, type: "indefinite") } → "a pair of gauntlets"
#   Example: { COUNT_ITEM("healing-potion", 3) } → "3 flasks of healing potion"
#
# Note: The `cap: "true"` parameter is used when the function result appears
# at sentence start. This is a pragmatic workaround since Fluent does not
# support function nesting like CAPITALIZE(COUNT_ITEM(...)).

## Messages

# Finding items (counter-aware)
found-item =
    { $count ->
        [one] You found { COUNT_ITEM($item, $count, type: "indefinite") }.
       *[other] You found { COUNT_ITEM($item, $count) }.
    }

# Item is here (sentence start - capitalize, counter-aware)
item-is-here =
    { $count ->
        [one] { COUNT_ITEM($item, $count, type: "definite", cap: "true") } is here.
       *[other] { COUNT_ITEM($item, $count, cap: "true") } are here.
    }

# Attack with item (count defaults to 1)
attack-with-item = You attack with { ARTICLE_ITEM($item, type: "definite") }.

# Drop item (counter-aware)
drop-item =
    { $count ->
        [one] You dropped { COUNT_ITEM($item, $count, type: "indefinite") }.
       *[other] You dropped { COUNT_ITEM($item, $count) }.
    }

# Inventory (counter-aware)
inventory-item =
    { $count ->
        [one] { COUNT_ITEM($item, $count, type: "indefinite") }
       *[other] { COUNT_ITEM($item, $count) }
    }

