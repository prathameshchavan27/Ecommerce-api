class CreatePayments < ActiveRecord::Migration[7.2]
  def change
    create_table :payments do |t|
      t.references :order, null: false, foreign_key: true
      t.string :status
      t.string :stripe_payment_intent_id
      t.integer :amount
      t.string :currency

      t.timestamps
    end
  end
end
