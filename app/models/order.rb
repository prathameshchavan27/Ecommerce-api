class Order < ApplicationRecord
  belongs_to :user
  has_many :order_items, dependent: :destroy
  enum :status, {
    pending: "pending",
    placed: "placed",
    processed: "processed",
    shipped: "shipped",
    in_transit: "in_transit",
    delivered: "delivered",
    cancelled: "cancelled"
  }

  validates :status, presence: true, inclusion: { in: statuses.keys }
  validates :total_price, presence: true, numericality: { greater_than_or_equal_to: 0 }

  def cancel!
    unless self.placed? || self.processed?
      errors.add(:base, "Order cannot be cancelled in its current status (#{self.status.humanize}).")
      return false # Indicate failure if not cancellable
    end

    # transaction for atomicity
    ActiveRecord::Base.transaction do
      # set order status to cancel
      self.cancelled!

      # restock products for each order items
      self.order_items.each do |item|
        product = item.product

        # update the product quantity
        # product.update!(stock: product.stock + item.quantity)
        product.increase_stock(item.quantity)
      end
      true
    rescue ActiveRecord::RecordInvalid => e
      # This block catches validation errors from `cancelled!` or `update!` on product
      errors.add(:base, "Cancellation failed due to data validation: #{e.message}")
      raise ActiveRecord::Rollback # Rollback the transaction
    rescue StandardError => e
      # This block catches any other unexpected errors during the transaction
      errors.add(:base, "An unexpected error occurred during cancellation: #{e.message}")
      raise ActiveRecord::Rollback # Rollback the transaction
    end
  end

  def cancellable?
    self.placed? || self.processing?
    # Add more complex logic here if needed (e.g., return false if shipped_at.present?)
  end
end
