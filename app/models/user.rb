class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :addresses, dependent: :destroy
  has_one :cart, dependent: :destroy
  has_many :orders, dependent: :restrict_with_error
  has_many :favorites, dependent: :destroy
  has_many :comments, dependent: :destroy
  # menambahkan relasi many-to-many antara User dan Product melalui model Favorite. Dengan ini, kita bisa mengakses produk favorit pengguna melalui user.favorite_products
  has_many :favorite_products, through: :favorites, source: :product 
  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true
  # validasi untuk memastikan bahwa password memiliki panjang minimal 6 karakter, tetapi hanya diterapkan saat membuat pengguna baru atau saat mengubah password. Jika password tidak diisi, validasi ini diabaikan.
  validates :password, length: { minimum: 6 }, if: -> { new_record? || !password.nil? }, allow_nil: true

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  enum :role, { customer: 0, admin: 1 }

  # searcfh untuk namaatau emailo customer
  def self.search(keyword)
    return all if keyword.blank?
    #sanitize_sql_like digunakan untuk membuat pola pencarian yang aman dengan menghindari karakter khusus yang dapat memengaruhi query SQL. 
    #seperti karakter wildcard % atau yang digunakan dalam LIKE query. Dengan menggunakan sanitize_sql_like, kita dapat memastikan bahwa input pengguna tidak akan menyebabkan masalah keamanan atau kesalahan sintaks SQL.
    pola="%#{sanitize_sql_like(keyword.strip)}%"
    where("users.name ILIKE :q OR users.email_address ILIKE :q", q: pola)
  end

  # Menambahkan kolom bayangan: jumlah_pesanan, total_belanja (hanya pesanan yang sudah dibayar),
  # dan pesanan_terakhir. left_joins supaya pengguna tanpa pesanan tetap muncul.
  scope :dengan_statistik, -> {
    laku = Order.statuses.values_at(*Order::LAKU).join(",")
    left_joins(:orders)
      .group("users.id")
      .select("users.*",
        "COUNT (orders.id) AS jumlah_pesanan",
        "COALESCE(SUM(orders.total) FILTER (WHERE orders.status IN (#{laku})), 0) AS total_belanja",
        "MAX(orders.created_at) AS pesanan_terakhir"
      )
  }
end
