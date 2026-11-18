class Category < ApplicationRecord
  # validasi untuk memastikan bahwa nama kategori tidak boleh kosong.
  validates :name, presence: true, uniqueness: true
  # asosiation untuk menghubungkan kategori dengan produk. Setiap kategori dapat memiliki banyak produk, dan jika kategori dihapus, produk yang terkait akan tetap ada tetapi kolom category_id pada produk akan diatur menjadi null.
  has_many :products, dependent: :nullify
end
