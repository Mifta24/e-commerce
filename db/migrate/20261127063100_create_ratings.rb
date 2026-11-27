class CreateRatings < ActiveRecord::Migration[8.1]
  def change
    create_table :ratings do |t|
      t.references :user, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.integer :stars, null: false

      t.timestamps
    end
    # Setiap user hanya boleh memberi rating satu kali untuk setiap produk.
    add_index :ratings, [:user_id, :product_id], unique: true
  end
end
