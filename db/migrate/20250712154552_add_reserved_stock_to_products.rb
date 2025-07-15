class AddReservedStockToProducts < ActiveRecord::Migration[7.2]
  def change
    add_column :products, :reserved_stock, :integer, default: 0, null: false
  end
end
