### German counter definitions

## Counter terms

# Paar (neuter) - invariant in plural after numbers
-paar = Paar
    .gender = neuter

# Flasche (feminine)
-flasche =
    { $count ->
        [one]
            { $case ->
                [nominative] Flasche
                [accusative] Flasche
                [dative] Flasche
               *[genitive] Flasche
            }
       *[other]
            { $case ->
                [nominative] Flaschen
                [accusative] Flaschen
                [dative] Flaschen
               *[genitive] Flaschen
            }
    }
    .gender = feminine
