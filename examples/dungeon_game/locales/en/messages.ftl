### Game messages for English

## Custom Functions
#
# ITEM($item, $count, type, cap)
#   Returns article + item name.
#   - type: "indefinite" (a/an), "definite" (the), or "none" (default: "indefinite")
#   Example: { ITEM("axe", type: "indefinite") } → "an axe"
#   Example: { ITEM("sword", type: "definite") } → "the sword"
#
# ITEM_WITH_COUNT($item, $count, type, cap)
#   Returns count + item, using counters when available.
#   For items with counters (e.g., gauntlet → pair), uses counter-based format.
#   - type: "indefinite", "definite", or "none" (default: "none")
#   Example: { ITEM_WITH_COUNT("sword", 3) } → "3 swords"
#   Example: { ITEM_WITH_COUNT("gauntlet", 1, type: "indefinite") } → "a pair of gauntlets"
#   Example: { ITEM_WITH_COUNT("healing-potion", 3) } → "3 flasks of healing potion"
#
# Note: The `cap: "true"` parameter is used when the function result appears
# at sentence start. This is a pragmatic workaround since Fluent does not
# support function nesting like CAPITALIZE(ITEM_WITH_COUNT(...)).

## Messages

# Finding items (counter-aware)
found-item =
    { $count ->
        [one] You found { ITEM_WITH_COUNT($item, $count, type: "indefinite") }.
       *[other] You found { ITEM_WITH_COUNT($item, $count) }.
    }

# Item is here (sentence start - capitalize, counter-aware)
item-is-here =
    { $count ->
        [one] { ITEM_WITH_COUNT($item, $count, type: "definite", cap: "true") } is here.
       *[other] { ITEM_WITH_COUNT($item, $count, cap: "true") } are here.
    }

# Attack with item (count defaults to 1)
attack-with-item = You attack with { ITEM($item, type: "definite") }.

# Drop item (counter-aware)
drop-item =
    { $count ->
        [one] You dropped { ITEM_WITH_COUNT($item, $count, type: "indefinite") }.
       *[other] You dropped { ITEM_WITH_COUNT($item, $count) }.
    }

# Inventory (counter-aware)
inventory-item =
    { $count ->
        [one] { ITEM_WITH_COUNT($item, $count, type: "indefinite") }
       *[other] { ITEM_WITH_COUNT($item, $count) }
    }

