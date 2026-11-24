class Favorite < ApplicationRecord
  belongs_to :user
  belongs_to :product, counter_cache: true  #counter_cache: :true  #counter_cache untuk menghitung jumlah favorit pada produk fitur dari rails untuk menghitung jumlah favorit pada produk. Dengan menambahkan counter_cache: true pada asosiasi belongs_to, Rails akan secara otomatis memperbarui kolom favorites_count pada tabel products setiap kali ada perubahan pada model Favorite yang terkait dengan produk tersebut. Ini memungkinkan kita untuk dengan cepat mengetahui berapa banyak pengguna yang telah menandai suatu produk sebagai favorit tanpa harus melakukan query tambahan ke tabel favorites.

  validates :user_id, uniqueness: { scope: :product_id, message: "Sudah memfavoritkan produk ini" }

end
