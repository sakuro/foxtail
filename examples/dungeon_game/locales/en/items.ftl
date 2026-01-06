### English item definitions

## Items

-dagger =
    { $count ->
        [one] dagger
       *[other] daggers
    }

-axe =
    { $count ->
        [one] axe
       *[other] axes
    }

-sword =
    { $count ->
        [one] sword
       *[other] swords
    }

-hammer =
    { $count ->
        [one] hammer
       *[other] hammers
    }

-herb =
    { $count ->
        [one] herb
       *[other] herbs
    }

## Items with counters

# Gauntlets are counted in pairs
-gauntlet = gauntlets
    .counter = -pair

# Healing potions are counted in flasks
-healing-potion = healing potion
    .counter = -flask

# Elixirs are counted in flasks
-elixir = elixir
    .counter = -flask
