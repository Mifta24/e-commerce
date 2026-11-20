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

 
  def self.top_of_the_month
    # count order pada product
    # order_items.count
    counts = OrderItem.group(:product_id).count
    # ambil produk dengan order terbanyak, kalau tidak ada yang punya order ambil produk terbaru yang punya deskripsi, kalau tidak ada yang punya deskripsi ambil produk terbaru
    where(id: counts.keys).max_by { |product| counts[product.id] } || where.not(description: [nil, ""]).order(created_at: :desc).first || order(created_at: :desc).first

  end
  def self.search(keyword)
    return all if keyword.blank?

    pola="%#{keyword.downcase}%"
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
