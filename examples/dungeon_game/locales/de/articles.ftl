### German article definitions


## Gender specification


#
# Each item must have a .gender attribute (masculine/feminine/neuter):
#
#   -sword = Schwert
#       .gender = neuter
#
#   -axe = Axt
#       .gender = feminine
#
# The article is selected based on gender, count, and grammatical case.


## Article terms

# Definite article (der/die/das)
# Uses $count for plural selection via PluralRules
-def-article =
    { $gender ->
        [masculine]
            { $count ->
                [one]
                    { $case ->
                       *[nominative] der
                        [accusative] den
                        [dative] dem
                        [genitive] des
                    }
               *[other]
                    { $case ->
                       *[nominative] die
                        [accusative] die
                        [dative] den
                        [genitive] der
                    }
            }
        [feminine]
            { $count ->
                [one]
                    { $case ->
                       *[nominative] die
                        [accusative] die
                        [dative] der
                        [genitive] der
                    }
               *[other]
                    { $case ->
                       *[nominative] die
                        [accusative] die
                        [dative] den
                        [genitive] der
                    }
            }
       *[neuter]
            { $count ->
                [one]
                    { $case ->
                       *[nominative] das
                        [accusative] das
                        [dative] dem
                        [genitive] des
                    }
               *[other]
                    { $case ->
                       *[nominative] die
                        [accusative] die
                        [dative] den
                        [genitive] der
                    }
            }
    }
# Indefinite article (ein/eine) - singular only
-indef-article =
    { $gender ->
        [masculine]
            { $case ->
               *[nominative] ein
                [accusative] einen
                [dative] einem
                [genitive] eines
            }
        [feminine]
            { $case ->
               *[nominative] eine
                [accusative] eine
                [dative] einer
                [genitive] einer
            }
       *[neuter]
            { $case ->
               *[nominative] ein
                [accusative] ein
                [dative] einem
                [genitive] eines
            }
    }
