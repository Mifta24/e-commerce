# Pengaturan tampilan nomor halaman (kaminari).
# Contoh dengan 20 halaman dan sedang di halaman 10:  1 … 8 9 [10] 11 12 … 20
Kaminari.configure do |config|
  config.window       = 2  # jumlah nomor di kiri dan kanan halaman aktif
  config.outer_window = 1  # jumlah nomor yang selalu tampil di ujung awal dan akhir
end
