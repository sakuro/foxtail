emails = { $count ->
    [one] You have one new email.
   *[other] You have { $count } new emails.
}
