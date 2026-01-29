### Game messages for Japanese


## Custom Functions


#
# ITEM($item)
#   Returns the item name.
#   - $item: Item term reference (e.g., "-sword", "-healing-potion")
#   Example: { ITEM("-sword") } → "剣"
#
# ITEM_WITH_COUNT($item, $count)
#   Returns count + counter + item name.
#   Format: "<count><counter>の<item>"
#   Each item has a counter defined in items.ftl (.counter attribute).
#   - $item: Item term reference
#   - $count: Number of items
#   Example: { ITEM_WITH_COUNT("-sword", 3) } → "3振の剣"
#   Example: { ITEM_WITH_COUNT("-gauntlet", 2) } → "2組の籠手"
#   Example: { ITEM_WITH_COUNT("-healing-potion", 5) } → "5瓶の回復薬"
#
# Japanese counters (助数詞) used in this example:
#   - 振 (ふり): For bladed weapons (sword, dagger, axe, hammer)
#   - 組 (くみ): For pairs/sets (gauntlets)
#   - 瓶 (びん): For bottled items (potions, elixir)
#   - 束 (たば): For bundled items (herbs)
#   - 枚 (まい): For flat items (coins)
#   - 個 (こ): Default counter when none specified


## Messages

# Finding items
found-item = { ITEM_WITH_COUNT($item, $count) }を見つけた。
# Item is here
item-is-here = { ITEM_WITH_COUNT($item, $count) }がある。
# Attack with item
attack-with-item = { ITEM($item) }で攻撃した。
# Drop item
drop-item = { ITEM_WITH_COUNT($item, $count) }を捨てた。
# Inventory
inventory-item = { ITEM_WITH_COUNT($item, $count) }
