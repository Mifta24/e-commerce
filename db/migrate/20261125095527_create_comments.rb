class CreateComments < ActiveRecord::Migration[8.1]
  def change
    create_table :comments do |t|
      t.references :user, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      # asosiation untuk menghubungkan komentar dengan komentar induknya. Setiap komentar dapat memiliki satu komentar induk, dan jika komentar induk dihapus, komentar yang terkait akan tetap ada tetapi kolom parent_id pada komentar akan diatur menjadi null.
      t.references :parent, foreign_key: { to_table: :comments }
      t.text :body, null: false
      t.integer :status , null: false, default: 0

      t.timestamps
    end
      add_index :comments, [ :product_id, :status ]
  end
end
