class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :status, null: false, default: 0
      t.integer :total, null: false, default: 0
      t.string :recipient_name, null: false
      t.string :phone, null: false
      t.text :street, null: false
      t.string :city, null: false
      t.string :province, null: false
      t.string :postal_code, null: false

      t.timestamps

      t.check_constraint "total >= 0", name: "orders_total_non_negative"
    end
  end
end
