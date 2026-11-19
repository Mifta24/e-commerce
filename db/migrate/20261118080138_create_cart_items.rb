class CreateCartItems < ActiveRecord::Migration[8.1]
  def change
    create_table :cart_items do |t|
      t.references :cart, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.string :product_name, null: false
      t.integer :quantity, null: false
      t.integer :unit_price, null: false

      t.timestamps

      t.index [:cart_id, :product_id], unique: true
      t.check_constraint "quantity > 0", name: "quantity_positive"
      t.check_constraint "unit_price >= 0", name: "unit_price_non_negative"
    end
  end
end
