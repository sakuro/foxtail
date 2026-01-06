### French item definitions

## Items

# Poignard (masculine)
-dagger =
    { $count ->
        [one] poignard
       *[other] poignards
    }
    .gender = masculine

# Hache (feminine, h aspiré - no elision)
-axe =
    { $count ->
        [one] hache
       *[other] haches
    }
    .gender = feminine
    .elision = false

# Épée (feminine, starts with vowel - elision)
-sword =
    { $count ->
        [one] épée
       *[other] épées
    }
    .gender = feminine

# Marteau (masculine)
-hammer =
    { $count ->
        [one] marteau
       *[other] marteaux
    }
    .gender = masculine

## Items with counters

# Gantelets (masculine, plural) - counted with paire
-gauntlet = gantelets
    .gender = masculine
    .counter = -paire

# Potion de soin (feminine) - counted with fiole
-healing-potion =
    { $count ->
        [one] potion de soin
       *[other] potions de soin
    }
    .gender = feminine
    .counter = -fiole

# Élixir (masculine) - counted with fiole, starts with vowel (tests elision)
-elixir =
    { $count ->
        [one] élixir
       *[other] élixirs
    }
    .gender = masculine
    .counter = -fiole
