class Product < ApplicationRecord
  belongs_to :category
  belongs_to :user
  
  validates :title, :price, :stock, :category_id, :user_id, presence: true
  validates :price, numericality: { greater_than: 0 }
  validates :stock, numericality: { greater_than_or_equal_to: 0 }
end
