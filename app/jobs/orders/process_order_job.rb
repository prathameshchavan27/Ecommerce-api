class Orders::ProcessOrderJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    user = User.find(user_id)
    cart = user.cart
    return if cart.blank? || cart.cart_items.blank?

    ActiveRecord::Base.transaction do
      order = user.orders.create!(
        total_price: cart.cart_items.sum { |item| item.quantity * item.product.price },
        status: :placed
      )

      cart.cart_items.includes(:product).each do |cart_item|
        product = cart_item.product
        quantity = cart_item.quantity

        if product.stock >= quantity
          # product.update!(stock: product.stock - quantity)
          product.decrease_stock(quantity)
          order.order_items.create!(
            product_id: product.id,
            quantity: quantity,
            price: product.price
          )
        else
          raise "Insufficient stock for #{product.title}"
        end
      end

      cart.cart_items.destroy_all
    end
  end
end
