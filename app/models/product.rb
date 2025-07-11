class Product < ApplicationRecord
  belongs_to :category
  belongs_to :user

  validates :title, :price, :stock, :category_id, :user_id, presence: true
  validates :price, numericality: { greater_than: 0 }
  validates :stock, numericality: { greater_than_or_equal_to: 0 }

  def decrease_stock(quantity)
    if self.stock < quantity
      raise InsufficientStockError, "Not enough stock for product #{self.id}. Available: #{self.stock}"
    end
    self.decrement!(:stock, quantity)
  end

  def increase_stock(quantity)
    self.increment!(:stock, quantity)
  end

  class InsufficientStockError < StandardError; end
  class ProductNotFoundError < StandardError; end
end
