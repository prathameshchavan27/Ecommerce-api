# app/serializers/cart_serializer.rb

class CartSerializer
  def initialize(cart)
    @cart = cart
  end

  def as_json(_options = {})
    {
      id: @cart.id,
      user_id: @cart.user_id,
      items: @cart.cart_items.includes(:product).map do |item|
        {
          id: item.id,
          product_id: item.product_id,
          product_title: item.product.title,
          quantity: item.quantity,
          price: item.product.price,
          total: item.quantity * item.product.price
        }
      end,
      total_price: @cart.cart_items.sum { |item| item.quantity * item.product.price }
    }
  end
end
