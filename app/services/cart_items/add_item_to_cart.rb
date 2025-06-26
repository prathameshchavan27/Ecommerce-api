module CartItems
  class AddItemToCart
    def initialize(cart, product_id, quantity)
      @cart = cart
      @product_id = product_id
      @quantity = quantity.to_i
    end

    def call
      cart_item = @cart.cart_items.find_by(product_id: @product_id)

      if cart_item
        cart_item.quantity += @quantity
      else
        cart_item = @cart.cart_items.new(product_id: @product_id, quantity: @quantity)
      end

      cart_item.save
      cart_item
    end
  end

end
