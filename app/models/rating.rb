class Rating < ApplicationRecord
  belongs_to :user
  belongs_to :product

  #  numericality membaca nilai mentah dari form jadi "4.5" dan "abc" ditolak
  validates :stars, numericality: {only_integer: true, in: 1..5}
  validates :user_id, uniqueness: {scope: :product_id, message: "hanya boleh memberi rating satu kali untuk setiap produk"}
  validate :harus_sudah_membeli

  private

  def harus_sudah_membeli
    return if user.nil? || product.nil? #kalau user atau product nil = kosong, validasi tidak dijalankan

    # unless digunakan untuk pengecualian jika kondisi tidak terpenuhi. Dalam hal ini, 
    # jika user belum membeli produk, maka akan menambahkan pesan kesalahan ke objek rating.
    unless user.sudah_membeli?(product)
      errors.add(:base, "Hanya pelanggan yang sudah membeli produk ini yang boleh memberi rating")
    end
  end
end
