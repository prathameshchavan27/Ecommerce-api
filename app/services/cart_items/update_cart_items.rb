module CartItems
    class UpdateCartItems
        def initialize(cart, cart_item_id, quantity)
            @cart = cart
            @cart_item_id = cart_item_id
            @quantity = quantity.to_i
        end

        def call
            cart_item = @cart.cart_items.find(@cart_item_id)
            unless cart_item
                return CartItem.new.tap { |ci| ci.errors.add(:base, "Cart item not found") }
            end

            if @quantity <= 0
                cart_item.errors.add(:quantity, "must be greater than 0")
                return cart_item
            end
            cart_item.quantity = @quantity
            cart_item.save
            cart_item
        end
    end
end
