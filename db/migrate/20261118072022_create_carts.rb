class CreateCarts < ActiveRecord::Migration[8.1]
  def change
    create_table :carts do |t|
      t.references :user, null: true, foreign_key: true, index: { unique: true }
      t.string :token, null: false
      t.timestamps
      t.index :token, unique: true
    end
  end
end
