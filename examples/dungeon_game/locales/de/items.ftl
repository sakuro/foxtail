### German item definitions


## Items

# Dolch (masculine)
-dagger =
    { $count ->
        [one]
            { $case ->
               *[nominative] Dolch
                [accusative] Dolch
                [dative] Dolch
                [genitive] Dolches
            }
       *[other]
            { $case ->
               *[nominative] Dolche
                [accusative] Dolche
                [dative] Dolchen
                [genitive] Dolche
            }
    }
    .gender = masculine
# Axt (feminine)
-axe =
    { $count ->
        [one]
            { $case ->
               *[nominative] Axt
                [accusative] Axt
                [dative] Axt
                [genitive] Axt
            }
       *[other]
            { $case ->
               *[nominative] Äxte
                [accusative] Äxte
                [dative] Äxten
                [genitive] Äxte
            }
    }
    .gender = feminine
# Schwert (neuter)
-sword =
    { $count ->
        [one]
            { $case ->
               *[nominative] Schwert
                [accusative] Schwert
                [dative] Schwert
                [genitive] Schwertes
            }
       *[other]
            { $case ->
               *[nominative] Schwerter
                [accusative] Schwerter
                [dative] Schwertern
                [genitive] Schwerter
            }
    }
    .gender = neuter
# Hammer (masculine)
-hammer =
    { $count ->
        [one]
            { $case ->
               *[nominative] Hammer
                [accusative] Hammer
                [dative] Hammer
                [genitive] Hammers
            }
       *[other]
            { $case ->
               *[nominative] Hämmer
                [accusative] Hämmer
                [dative] Hämmern
                [genitive] Hämmer
            }
    }
    .gender = masculine
# Kraut (neuter)
-herb =
    { $count ->
        [one]
            { $case ->
               *[nominative] Kraut
                [accusative] Kraut
                [dative] Kraut
                [genitive] Krautes
            }
       *[other]
            { $case ->
               *[nominative] Kräuter
                [accusative] Kräuter
                [dative] Kräutern
                [genitive] Kräuter
            }
    }
    .gender = neuter
# Goldmünze (feminine)
-gold-coin =
    { $count ->
        [one]
            { $case ->
               *[nominative] Goldmünze
                [accusative] Goldmünze
                [dative] Goldmünze
                [genitive] Goldmünze
            }
       *[other]
            { $case ->
               *[nominative] Goldmünzen
                [accusative] Goldmünzen
                [dative] Goldmünzen
                [genitive] Goldmünzen
            }
    }
    .gender = feminine

## Items with counters

# Panzerhandschuhe (plurale tantum) - counted with Paar
-gauntlet =
    { $case ->
        [dative] Panzerhandschuhen
       *[other] Panzerhandschuhe
    }
    .gender = masculine
    .counter = -paar
# Heiltrank (masculine) - counted with Flasche
-healing-potion =
    { $count ->
        [one]
            { $case ->
               *[nominative] Heiltrank
                [accusative] Heiltrank
                [dative] Heiltrank
                [genitive] Heiltrankes
            }
       *[other]
            { $case ->
               *[nominative] Heiltränke
                [accusative] Heiltränke
                [dative] Heiltränken
                [genitive] Heiltränke
            }
    }
    .gender = masculine
    .counter = -flasche
# Elixier (neuter) - counted with Flasche
-elixir =
    { $count ->
        [one]
            { $case ->
               *[nominative] Elixier
                [accusative] Elixier
                [dative] Elixier
                [genitive] Elixiers
            }
       *[other]
            { $case ->
               *[nominative] Elixiere
                [accusative] Elixiere
                [dative] Elixieren
                [genitive] Elixiere
            }
    }
    .gender = neuter
    .counter = -flasche
