class AddUniqueIndexToCategoriesName < ActiveRecord::Migration[8.1]
  def change
    # menambahkan index unik pada kolom name di tabel categories. Index ini memastikan bahwa tidak ada dua kategori yang memiliki nama yang sama, sehingga mencegah duplikasi data. Index ini juga menggunakan fungsi lower untuk mengabaikan perbedaan huruf besar dan kecil saat memeriksa keunikan nama kategori.
    add_index :categories, "lower(name)", unique: true, name: "index_categories_on_lower_name"
  end
end
