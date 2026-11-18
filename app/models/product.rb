class Product < ApplicationRecord
  # validasi untuk memastikan bahwa nama produk tidak boleh kosong, harga harus berupa angka yang lebih besar dari atau sama dengan 0, dan stok juga harus berupa angka yang lebih besar dari atau sama dengan 0.
  validates :name, presence: true
  validates :price,   numericality: { greater_than_or_equal_to: 0 }
  validates :stock,   numericality: { greater_than_or_equal_to: 0 }

  # asosiation untuk menghubungkan produk dengan kategori. Setiap produk dapat memiliki satu kategori, dan jika kategori dihapus, produk yang terkait akan tetap ada tetapi kolom category_id pada produk akan diatur menjadi null.
  belongs_to :category, optional: true
end
