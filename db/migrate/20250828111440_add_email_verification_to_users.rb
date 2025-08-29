class AddEmailVerificationToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :email_verified, :boolean
    add_column :users, :otp_code, :string
    add_column :users, :otp_sent_at, :datetime
  end
end
