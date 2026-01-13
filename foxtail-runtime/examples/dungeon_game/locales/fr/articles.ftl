### French article definitions


## Elision control


#
# By default, elision occurs before vowels (l'épée, l'arme).
# Words starting with consonants (including h) do not elide by default.
#
# For h muet words (silent h, elision required), add .elision = true:
#
#   # "l'herbe" - h muet, elision required
#   -herb = herbe
#       .gender = feminine
#       .elision = true
#
#   # "l'homme" - h muet, elision required
#   -man = homme
#       .gender = masculine
#       .elision = true
#
# For h aspiré words, no attribute is needed (h is not a vowel):
#
#   # "la hache" - h aspiré, no elision (default behavior)
#   -axe = hache
#       .gender = feminine


## Format patterns


#
# Patterns for joining article with item/counter.
# Uses $elision selector to handle l'/d' (no space after apostrophe).

-fmt-article-item =
    { $elision ->
        [true] { $article }{ $item }
       *[false] { $article } { $item }
    }
-fmt-article-counter-item =
    { $article_elision ->
        [true]
            { $counter_elision ->
                [true] { $article }{ $counter }{ $item }
               *[false] { $article }{ $counter } { $item }
            }
       *[false]
            { $counter_elision ->
                [true] { $article } { $counter }{ $item }
               *[false] { $article } { $counter } { $item }
            }
    }
-fmt-counter-item =
    { $elision ->
        [true] { $counter }{ $item }
       *[false] { $counter } { $item }
    }
-fmt-count-counter-item =
    { $elision ->
        [true] { $count } { $counter }{ $item }
       *[false] { $count } { $counter } { $item }
    }

## Article terms

# Definite article (le/la/l'/les)
# Uses $count for plural selection via PluralRules
-def-article =
    { $elision ->
        [true] l'
       *[false]
            { $count ->
                [one]
                    { $gender ->
                        [feminine] la
                       *[masculine] le
                    }
               *[other] les
            }
    }
# Indefinite article (un/une/des)
# Uses $count for plural selection via PluralRules
-indef-article =
    { $count ->
        [one]
            { $gender ->
                [feminine] une
               *[masculine] un
            }
       *[other] des
    }
