class Product < ApplicationRecord
  acts_as_paranoid

  belongs_to :category
  belongs_to :user
  has_many :cart_items, dependent: :destroy
  has_many :order_items

  validates :title, :price, :stock, :category_id, :user_id, presence: true
  validates :price, numericality: { greater_than: 0 }
  validates :stock, numericality: { greater_than_or_equal_to: 0 }
  validates :reserved_stock, numericality: { greater_than_or_equal_to: 0 }

  def decrease_stock(quantity)
    raise ArgumentError, "Quantity for decreasing stock must be a positive integer." unless quantity.is_a?(Integer) && quantity > 0
    # Use with_lock to ensure atomic update and prevent race conditions
    # This will lock the specific product row in the database during the block
    with_lock do
      # Reload the product instance within the lock to get the freshest data
      # This is CRUCIAL as another process might have changed stock before the lock
      reload
      if self.stock < quantity
        raise InsufficientStockError, "Not enough total stock for product #{self.id}. Available: #{self.stock}, Requested: #{quantity}"
      end
      self.decrement!(:stock, quantity) # This will save the changes
    end
  end

  def increase_stock(quantity)
    raise ArgumentError, "Quantity for increasing stock must be a positive integer." unless quantity.is_a?(Integer) && quantity > 0
    with_lock do
      reload # Reload the product instance within the lock
      self.increment!(:stock, quantity) # This will save the changes
    end
  end

  def reserve_stock(quantity)
    raise ArgumentError, "Quantity for reservation must be a positive integer." unless quantity.is_a?(Integer) && quantity > 0
    Product.transaction do
      product = Product.lock.find(self.id)
      if (product.stock-reserved_stock) < quantity
        raise InsufficientStockError, "Not enough available stock for product #{product.id}. Available for sale: #{product.available_for_sale}, Requested: #{quantity}"
      end
      product.increment!(:reserved_stock, quantity)
      self.reload
    end
  end

  def confirm_reservation_and_sell(quantity)
    raise ArgumentError, "Quantity for sale confirmation must be a positive integer." unless quantity.is_a?(Integer) && quantity > 0

    with_lock do
      reload # Get the latest data under lock
      if self.reserved_stock < quantity
        # This indicates a logic error or race condition in the payment flow
        raise InsufficientStockError, "Not enough reserved stock for product #{self.id}. Reserved: #{self.reserved_stock}, Attempted to sell: #{quantity}"
      end

      self.decrement!(:stock, quantity)
      self.decrement!(:reserved_stock, quantity)
    end
  end

  def release_reserved_stock(quantity)
    raise ArgumentError, "Quantity for releasing reservation must be a positive integer." unless quantity.is_a?(Integer) && quantity > 0

    with_lock do
      reload # Get the latest data under lock
      if self.reserved_stock < quantity
        Rails.logger.warn "Attempted to release more reserved stock (#{quantity}) than available (#{self.reserved_stock}) for product #{self.id}. Releasing available amount."
        quantity = self.reserved_stock # Release only what's available to prevent negative reserved_stock
        return if quantity == 0 # Nothing to release
      end

      self.decrement!(:reserved_stock, quantity)
    end
  end

  def available_for_sale
    stock - reserved_stock
  end

  class InsufficientStockError < StandardError; end
  class ProductNotFoundError < StandardError; end
end
