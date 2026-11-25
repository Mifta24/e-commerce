class Product < ApplicationRecord
  # validasi untuk memastikan bahwa nama produk tidak boleh kosong, harga harus berupa angka yang lebih besar dari atau sama dengan 0, dan stok juga harus berupa angka yang lebih besar dari atau sama dengan 0.
  validates :name, presence: true
  validates :price,   numericality: { greater_than_or_equal_to: 0 }
  validates :stock,   numericality: { greater_than_or_equal_to: 0 }
  validate :image_must_be_valid

  has_many :cart_items, dependent: :destroy
  has_many :order_items, dependent: :restrict_with_error
  has_many :favorites, dependent: :destroy
  # asosiation untuk menghubungkan produk dengan kategori. Setiap produk dapat memiliki satu kategori, dan jika kategori dihapus, produk yang terkait akan tetap ada tetapi kolom category_id pada produk akan diatur menjadi null.
  belongs_to :category, optional: true
  has_one_attached :image
  # scope digunakan untuk membuat query yang dapat digunakan kembali. Dalam hal ini, scope :menipis digunakan untuk mengambil produk dengan stok antara 1 hingga LOW_STOCK, sedangkan scope :habis digunakan untuk mengambil produk dengan stok 0.
  # stok dianggap menipis kalau tinggal segini atau kurang (tapi belum habis)
  LOW_STOCK = 5
  scope :menipis, -> { where(stock: 1..LOW_STOCK) }
  scope :habis, -> { where(stock: 0) }
 
# Produk terlaris 30 hari terakhir, dihitung dari jumlah barang (quantity)
# pada pesanan yang sudah dibayar. Kalau belum ada penjualan, ambil produk terbaru.
def self.top_of_the_month
  #  cari pesanan dengan status paid, shipped, atau completed yang dibuat dalam 30 hari terakhir. Ini akan digunakan untuk menghitung produk terlaris berdasarkan jumlah barang yang dipesan.
  pesanan_laku = Order.where(status: %i[paid shipped completed], created_at: 30.days.ago..Time.current)
# menggunakan Arel.sql untuk menghindari masalah dengan sintaks SQL yang kompleks. Arel adalah pustaka Ruby yang digunakan oleh ActiveRecord untuk membangun kueri SQL secara dinamis. Dengan menggunakan Arel.sql, kita dapat menyisipkan potongan SQL mentah ke dalam kueri ActiveRecord tanpa harus khawatir tentang masalah sintaks atau keamanan. Dalam hal ini, kita menggunakan Arel.sql untuk menyusun kueri yang menghitung jumlah barang (quantity) dari order_items yang terkait dengan pesanan yang sudah dibayar dalam 30 hari terakhir.
  top_id = OrderItem
    .joins(:order) # join tabel orders
    .merge(pesanan_laku) # menggabungkan kondisi dari pesanan_laku
    .group(:product_id) # mengelompokkan hasil berdasarkan product_id
    .order(Arel.sql("SUM(order_items.quantity) DESC")) # mengurutkan hasil berdasarkan jumlah barang yang dipesan secara menurun
    .pick(:product_id) # mengambil product_id dari produk terlaris

  find_by(id: top_id) ||
    where.not(description: [ nil, "" ]).order(created_at: :desc).first ||
    order(created_at: :desc).first
end

  def self.search(keyword)
    return all if keyword.blank?

    # pola = "%#{keyword.downcase}%"
    # sanitize_sql_like digunakan untuk membuat pola pencarian yang aman dengan menghindari karakter khusus yang dapat memengaruhi query SQL.
    pola = "%#{sanitize_sql_like(keyword.strip)}%"
    where("name ILIKE :q OR description ILIKE :q", q: pola)
  end

  private

# validasi untuk memastikan bahwa gambar yang diunggah adalah dalam format JPG, PNG, atau WebP dan ukurannya tidak melebihi 5 MB. Jika gambar tidak valid, akan menambahkan pesan kesalahan ke objek produk.
  def image_must_be_valid
    return unless image.attached?

    unless %w[image/jpeg image/png image/webp].include?(image.content_type)
      errors.add(:image, "harus berformat JPG, PNG, atau WebP")
    end

    if image.byte_size > 5.megabytes
      errors.add(:image, "maksimal 5 MB")
    end
  end


end
