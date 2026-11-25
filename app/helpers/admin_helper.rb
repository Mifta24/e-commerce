module AdminHelper
  # Satu tautan di sidebar admin.
  # aktif: true kalau halaman yang sedang dibuka ada di bagian ini
  # badge: angka kecil merah di kanan (disembunyikan kalau 0)
  def admin_nav_link(label, icon, path, aktif:, badge: 0)
    link_to path, class: "nav-link d-flex align-items-center gap-2 #{'active' if aktif}" do
      safe_join([
        tag.i(class: "bi bi-#{icon}"),
        tag.span(label),
        (tag.span(badge, class: "badge text-bg-danger ms-auto") if badge > 0)
      ])
    end
  end


  # Teks konfirmasi sebelum menghapus kategori. Produk di dalamnya tidak ikut terhapus.
  def pesan_hapus_kategori(category)
    pesan = "Yakin hapus kategori #{category.name}?"
    pesan += " #{category.jumlah_produk} produk di dalamnya akan jadi tanpa kategori." if category.jumlah_produk > 0
    pesan
  end
end 