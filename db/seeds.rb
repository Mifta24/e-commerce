# Data awal untuk development. Aman dijalankan berulang kali (idempotent):
# data yang sudah ada diperbarui, bukan digandakan.
#
#   bin/rails db:seed          # tambah / perbarui data
#   bin/rails db:reset         # kosongkan database, migrasi ulang, lalu seed

# ---------------------------------------------------------------------------
# Kategori + produk
# ---------------------------------------------------------------------------
# Format tiap produk: [nama, harga (Rp), stok, deskripsi]
CATALOG = {
  "Pakaian" => [
    [ "Kaos Polos Katun", 75_000, 40, "Kaos katun combed 30s yang adem dan nyaman dipakai sehari-hari." ],
    [ "Kemeja Flanel Kotak", 185_000, 25, "Kemeja flanel lengan panjang dengan motif kotak klasik." ],
    [ "Hoodie Oversize", 220_000, 18, "Hoodie fleece tebal dengan potongan oversize dan kantong depan." ],
    [ "Celana Chino Slim", 195_000, 30, "Celana chino slim fit dari bahan twill yang tidak mudah kusut." ],
    [ "Jaket Denim", 310_000, 12, "Jaket denim klasik dengan cuci medium blue." ]
  ],
  "Sepatu" => [
    [ "Sneakers Putih Klasik", 450_000, 20, "Sneakers kulit sintetis warna putih, cocok untuk semua gaya." ],
    [ "Sepatu Lari Ringan", 520_000, 15, "Sepatu lari dengan sol empuk dan bobot ringan." ],
    [ "Sandal Jepit Karet", 45_000, 80, "Sandal jepit karet anti slip untuk santai." ],
    [ "Sepatu Kulit Formal", 680_000, 8, "Sepatu pantofel kulit asli untuk acara resmi dan kantor." ],
    [ "Sepatu Slip-On Kanvas", 235_000, 35, "Sepatu slip-on kanvas praktis tanpa tali." ]
  ],
  "Aksesoris" => [
    [ "Topi Baseball", 65_000, 50, "Topi baseball katun dengan strap yang bisa diatur." ],
    [ "Tas Ransel Urban", 285_000, 22, "Ransel dengan kompartemen laptop 14 inci dan bahan tahan air." ],
    [ "Ikat Pinggang Kulit", 120_000, 28, "Ikat pinggang kulit dengan gesper stainless." ],
    [ "Kacamata Hitam Retro", 95_000, 0, "Kacamata hitam dengan lensa anti UV400." ],
    [ "Dompet Lipat Kulit", 135_000, 33, "Dompet lipat kulit dengan banyak slot kartu." ]
  ],
  "Elektronik" => [
    [ "Earbuds Nirkabel", 299_000, 45, "Earbuds Bluetooth 5.3 dengan casing pengisi daya." ],
    [ "Power Bank 10000 mAh", 175_000, 38, "Power bank ramping dengan dua port keluaran." ],
    [ "Speaker Bluetooth Mini", 249_000, 16, "Speaker portabel tahan cipratan air, baterai hingga 8 jam." ],
    [ "Smartwatch Fitness", 650_000, 10, "Jam pintar dengan sensor detak jantung dan pelacak tidur." ],
    [ "Mouse Nirkabel", 89_000, 60, "Mouse nirkabel 2.4 GHz yang senyap dan ergonomis." ]
  ],
  "Rumah Tangga" => [
    [ "Botol Minum Stainless", 110_000, 55, "Botol minum 750 ml, menjaga suhu hingga 12 jam." ],
    [ "Set Piring Keramik", 165_000, 14, "Satu set 6 piring keramik motif sederhana." ],
    [ "Lampu Meja LED", 135_000, 27, "Lampu meja LED dengan tiga tingkat kecerahan." ],
    [ "Handuk Katun Besar", 85_000, 42, "Handuk katun tebal yang cepat menyerap air." ],
    [ "Kotak Penyimpanan Lipat", 70_000, 3, "Kotak penyimpanan lipat untuk merapikan lemari." ]
  ]
}.freeze

CATALOG.each do |category_name, items|
  category = Category.find_or_create_by!(name: category_name)

  items.each do |name, price, stock, description|
    product = Product.find_or_initialize_by(name: name)
    product.update!(price: price, stock: stock, description: description, category: category)
  end
end

puts "Kategori: #{Category.count}, Produk: #{Product.count}"

# ---------------------------------------------------------------------------
# Akun contoh (hanya di development, supaya tidak ada password bawaan di production)
# ---------------------------------------------------------------------------
if Rails.env.development?
  DEV_PASSWORD = "password123".freeze

  [
    { email_address: "admin@example.com",    name: "Admin Toko",    role: :admin,    phone: "081200000001" },
    { email_address: "customer@example.com", name: "Budi Pelanggan", role: :customer, phone: "081200000002" }
  ].each do |attrs|
    user = User.find_or_initialize_by(email_address: attrs[:email_address])
    user.assign_attributes(name: attrs[:name], role: attrs[:role], phone: attrs[:phone])
    user.password = user.password_confirmation = DEV_PASSWORD if user.new_record?
    user.save!
  end

  customer = User.find_by!(email_address: "customer@example.com")
  customer.addresses.find_or_create_by!(street: "Jl. Merdeka No. 10, RT 02/RW 05") do |address|
    address.recipient_name = "Budi Pelanggan"
    address.phone          = "081200000002"
    address.city           = "Bandung"
    address.province       = "Jawa Barat"
    address.postal_code    = "40111"
  end

  puts "Akun: admin@example.com / customer@example.com (password: #{DEV_PASSWORD})"
end
