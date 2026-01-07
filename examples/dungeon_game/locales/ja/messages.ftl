### Game messages for Japanese


## Custom Functions


#
# ITEM($item, $count, cap)
#   Returns the item name.
#   - $item: Item ID (e.g., "sword", "healing-potion")
#   - $count: Number of items (default: 1, not used for Japanese)
#   Example: { ITEM("sword") } → "剣"
#
# COUNT($item, $count)
#   Returns count with the appropriate counter (助数詞).
#   Each item has a counter defined in items.ftl (.counter attribute).
#   - $item: Item ID
#   - $count: Number of items
#   Example: { COUNT("sword", 3) } → "3振"
#   Example: { COUNT("gauntlet", 2) } → "2組"
#   Example: { COUNT("healing-potion", 1) } → "1瓶"
#
# Japanese counters (助数詞) used in this example:
#   - 振 (ふり): For bladed weapons (sword, dagger, axe, hammer)
#   - 組 (くみ): For pairs/sets (gauntlets)
#   - 瓶 (びん): For bottled items (potions, elixir)
#   - 個 (こ): Default counter when none specified


## Messages

# Finding items (counter-aware)
found-item = { ITEM($item) }を{ COUNT($item, $count) }見つけた。
# Item is here
item-is-here = { ITEM($item) }が{ COUNT($item, $count) }ある。
# Attack with item (count defaults to 1)
attack-with-item = { ITEM($item) }で攻撃した。
# Drop item
drop-item = { ITEM($item) }を{ COUNT($item, $count) }捨てた。
# Inventory
inventory-item = { ITEM($item) } x { COUNT($item, $count) }
