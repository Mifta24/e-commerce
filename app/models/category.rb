class Category < ApplicationRecord
  # validasi untuk memastikan bahwa nama kategori tidak boleh kosong.
  validates :name, presence: true, uniqueness: true
  # normalization untuk memastikan bahwa nama kategori disimpan dalam format yang konsisten, yaitu dengan menghapus spasi di awal dan akhir serta mengubah semua huruf menjadi huruf kecil.
  # asosiation untuk menghubungkan kategori dengan produk. Setiap kategori dapat memiliki banyak produk, dan jika kategori dihapus, produk yang terkait akan tetap ada tetapi kolom category_id pada produk akan diatur menjadi null.
  has_many :products, dependent: :nullify
end
