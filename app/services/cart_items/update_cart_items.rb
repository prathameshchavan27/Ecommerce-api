module CartItems
    class UpdateCartItems
        def initialize(cart,cart_item_id, quantity)
            @cart = cart
            @cart_item_id = cart_item_id
            @quantity = quantity
        end

        def call
            cart_item = @cart.cart_items.find(@cart_item_id)
            cart_item.quantity = @quantity
            cart_item.save
            cart_item
        end
    end
end