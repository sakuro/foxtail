# E-commerce English translations

# Product information
product-name = { $name }
product-price = { NUMBER($price, style: "currency", currency: "USD") }
product-discount = { NUMBER($percent, style: "percent") } off
# Stock status with plurals
stock-status =
    { $count ->
        [0] Out of stock
        [one] Only { $count } left in stock!
       *[other] { $count } items in stock
    }
# Cart messages
cart-items =
    { $count ->
        [0] Your cart is empty
        [one] { $count } item in cart
       *[other] { $count } items in cart
    }
cart-total = Total: { NUMBER($total, style: "currency", currency: "USD") }
# Shipping
shipping-free = Free shipping on orders over { NUMBER($threshold, style: "currency", currency: "USD") }
shipping-cost = Shipping: { NUMBER($cost, style: "currency", currency: "USD") }
# Reviews
reviews-count =
    { $count ->
        [0] No reviews yet
        [one] { $count } customer review
       *[other] { $count } customer reviews
    }
reviews-rating = { NUMBER($rating, minimumFractionDigits: 1, maximumFractionDigits: 1) } out of 5 stars
# Sale
sale-banner = SALE! Save up to { NUMBER($maxDiscount, style: "percent") }
