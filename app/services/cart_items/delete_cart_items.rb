module CartItems
    class DeleteCartItems
        def initialize(cart, cart_item_id)
            @cart = cart
            @cart_item_id = cart_item_id
        end

        def call
            cart_item = @cart.cart_items.find_by(id: @cart_item_id)
            unless cart_item
                return CartItem.new.tap { |ci| ci.errors.add(:base, "Cart item not found") }
            end

            if cart_item.destroy
                cart_item
            else
                cart_item.errors.add(:base, "Failed to delete cart item")
                cart_item
            end
        end
    end
end
