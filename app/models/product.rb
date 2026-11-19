class Product < ApplicationRecord
  # validasi untuk memastikan bahwa nama produk tidak boleh kosong, harga harus berupa angka yang lebih besar dari atau sama dengan 0, dan stok juga harus berupa angka yang lebih besar dari atau sama dengan 0.
  validates :name, presence: true
  validates :price,   numericality: { greater_than_or_equal_to: 0 }
  validates :stock,   numericality: { greater_than_or_equal_to: 0 }

  has_many :cart_items, dependent: :destroy
  has_many :order_items, dependent: :restrict_with_error
  # asosiation untuk menghubungkan produk dengan kategori. Setiap produk dapat memiliki satu kategori, dan jika kategori dihapus, produk yang terkait akan tetap ada tetapi kolom category_id pada produk akan diatur menjadi null.
  belongs_to :category, optional: true

  # Produk unggulan bulan ini. Belum ada data penjualan, jadi sementara diambil produk terbaru yang punya deskripsi
  # (atau produk terbaru kalau tidak ada yang punya deskripsi). Ganti logika ini kalau data pesanan sudah ada.
  def self.top_of_the_month
    where.not(description: [ nil, "" ]).order(created_at: :desc).first || order(created_at: :desc).first
  end

  def self.search(keyword)
    retrun all if keyword.blank?

    pola="%#{keyword.downcase}%"
    where("name ILIKE :q OR description ILIKE :q", q: pola)
  end

end
