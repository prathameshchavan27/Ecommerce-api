class Order < ApplicationRecord
  belongs_to :user
  has_many :order_items, dependent: :destroy
  enum :status, {
    placed: "placed",
    processed: "processed",
    shipped: "shipped",
    in_transit: "in_transit",
    delivered: "delivered",
    cancelled: "cancelled"
  }

  validates :status, presence: true, inclusion: { in: statuses.keys }
  validates :total_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
end
