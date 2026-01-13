# E-commerce 日本語翻訳

# 商品情報
product-name = { $name }
product-price = { NUMBER($price, style: "currency", currency: "JPY") }
product-discount = { NUMBER($percent, style: "percent") }オフ
# 在庫状況
stock-status =
    { $count ->
        [0] 在庫切れ
        [one] 残り{ $count }点のみ！
       *[other] 在庫{ $count }点
    }
# カート
cart-items =
    { $count ->
        [0] カートは空です
       *[other] カートに{ $count }点
    }
cart-total = 合計：{ NUMBER($total, style: "currency", currency: "JPY") }
# 配送
shipping-free = { NUMBER($threshold, style: "currency", currency: "JPY") }以上で送料無料
shipping-cost = 送料：{ NUMBER($cost, style: "currency", currency: "JPY") }
# レビュー
reviews-count =
    { $count ->
        [0] レビューはまだありません
       *[other] { $count }件のレビュー
    }
reviews-rating = { NUMBER($rating, minimumFractionDigits: 1, maximumFractionDigits: 1) } / 5.0
# セール
sale-banner = セール中！最大{ NUMBER($maxDiscount, style: "percent") }オフ
