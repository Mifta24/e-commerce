class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products do |t|
      t.string :name, null: false
      t.text :description
      t.integer :price, null: false, default: 0
      t.integer :stock, null: false, default: 0

      t.timestamps
    end
  end
end
