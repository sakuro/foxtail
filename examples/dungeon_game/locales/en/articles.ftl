### English article definitions


## Exception handling


#
# By default, indefinite article is "a" before consonants and "an" before vowels.
# For exceptions, add .indef attribute to the item term:
#
#   # "an hour" - silent h, use "an"
#   -hour = hour
#       .indef = an
#
#   # "a unicorn" - sounds like "yoo", use "a"
#   -unicorn = unicorn
#       .indef = a


## Article terms

# Definite article (always "the")
-def-article = the
# Indefinite article (a/an based on first letter)
# Pass $first_letter as lowercase first character of the following word
-indef-article =
    { $first_letter ->
        [a] an
        [e] an
        [i] an
        [o] an
        [u] an
       *[other] a
    }
