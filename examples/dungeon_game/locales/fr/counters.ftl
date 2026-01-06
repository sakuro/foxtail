### French counter definitions

## Counter elision
#
# Counters use $elision selector for "de" vs "d'" based on the following item.
# The elision is determined by whether the item starts with a vowel.
#
# Example: "fiole de potion" vs "fiole d'élixir"

## Counter terms

# Paire (feminine) - uses elision selector for "de" vs "d'"
-paire =
    { $elision ->
        [true]
            { $count ->
                [one] paire d'
               *[other] paires d'
            }
       *[false]
            { $count ->
                [one] paire de
               *[other] paires de
            }
    }
    .gender = feminine

# Fiole (feminine) - uses elision selector for "de" vs "d'"
-fiole =
    { $elision ->
        [true]
            { $count ->
                [one] fiole d'
               *[other] fioles d'
            }
       *[false]
            { $count ->
                [one] fiole de
               *[other] fioles de
            }
    }
    .gender = feminine
