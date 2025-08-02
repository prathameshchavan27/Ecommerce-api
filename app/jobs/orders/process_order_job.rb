class Orders::ProcessOrderJob < ApplicationJob
  queue_as :default

  # The job is now only triggered with a pending order's ID
  def perform(order_id)
    order = Order.find_by(id: order_id, status: :pending)
    return unless order

    ActiveRecord::Base.transaction do
      order.order_items.includes(:product).each do |order_item|
        product = order_item.product
        quantity = order_item.quantity

        # Finalize the stock changes. This assumes reserve_stock has already been called
        product.confirm_reservation_and_sell(quantity)
      end

      order.update!(status: :placed)
      order.user.cart.cart_items.destroy_all # Clear cart
    end

  rescue StandardError => e
    # Log the error, but the transaction will handle the rollback.
    Rails.logger.error "Order finalization failed for Order ID #{order_id}: #{e.message}"
    # Optionally, you might want to release the reserved stock if it wasn't
    # automatically done by the transaction rollback in a more complex flow.
  end
end