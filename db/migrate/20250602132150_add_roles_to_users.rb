class AddRolesToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :roles_mask, :integer
  end
end
