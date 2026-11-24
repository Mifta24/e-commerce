class AddFavoritesCountToProducts < ActiveRecord::Migration[8.1]
  def up
    add_column :products, :favorites_count, :integer, default: 0, null: false

    # Isi angka awal dari data yang sudah ada
    execute <<~SQL
      UPDATE products
      SET favorites_count = (
        SELECT COUNT(*) FROM favorites WHERE favorites.product_id = products.id
      )
    SQL
  end

  def down
    remove_column :products, :favorites_count
  end
end
