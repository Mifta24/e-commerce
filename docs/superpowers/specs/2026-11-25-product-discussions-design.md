# Diskusi Produk dengan Moderasi — Desain Singkat

Tanggal: 2026-11-25. Status: menunggu persetujuan.

## Tujuan dan alasan
Pembeli biasanya ingin bertanya soal produk sebelum membeli. Halaman produk dibuat punya bagian diskusi yang bisa dibaca publik. Pembeli yang login boleh bertanya dan saling menjawab. Admin bisa menyembunyikan isi yang melanggar. Fitur ini juga bahan belajar Rails untuk pemilik proyek, jadi pola yang dipakai harus mudah diikuti dan mirip kode yang sudah ada (Favorite, Admin::Orders).

## Bukan tujuan
- Mengedit atau menghapus komentar oleh penulisnya.
- Tombol "Laporkan" dan tabel laporan (tahap berikutnya, bisa ditambah di atas desain ini).
- Balasan bertingkat lebih dari satu level, notifikasi email, gambar atau teks kaya, paginasi di halaman produk.
- Counter cache jumlah komentar (status tampil/disembunyikan membuatnya lebih rumit dari manfaatnya).

## Anti-tujuan (dianggap gagal walau secara teknis jalan)
- Komentar milik pengunjung yang belum login bisa masuk.
- Isi komentar dirender sebagai HTML mentah (celah XSS).
- Komentar yang disembunyikan masih terbaca oleh publik.

## Pendekatan yang dipertimbangkan
1. **Satu tabel `comments`, balasan satu tingkat (dipilih).** Paling sederhana dan paling mudah dipelajari.
2. Seperti 1 ditambah "Laporkan". Ditunda: satu tabel dan satu alur tambahan, bisa menyusul.
3. Balasan bertingkat tanpa batas (gem seperti `ancestry`). Ditolak: menyembunyikan bagian belajar dan sulit ditampilkan di layar HP.

Moderasi: komentar langsung tampil, admin bisa menyembunyikan (keputusan pemilik: pakai usulan ini).

## Desain

**Data.** Tabel `comments`: `user_id` (wajib), `product_id` (wajib), `parent_id` (boleh kosong, merujuk ke `comments.id`), `body` (text, wajib), `status` (integer, default 0), timestamps. Indeks pada `[product_id, status]` dan `parent_id`.

**Model `Comment`.**
- `belongs_to :user`, `belongs_to :product`, `belongs_to :parent, class_name: "Comment", optional: true`, `has_many :replies, class_name: "Comment", foreign_key: :parent_id, dependent: :destroy`.
- `enum :status, { tampil: 0, disembunyikan: 1 }` (penamaan Indonesia mengikuti scope yang sudah ada, mis. `menipis`, `habis`).
- Validasi: `body` wajib, maksimal 1000 karakter. Jika `parent` ada, ia harus milik produk yang sama dan harus komentar utama (`parent_id` kosong).
- Scope `utama` (`parent_id` kosong) dan urutan lama ke baru.
- `Product` dan `User`: `has_many :comments, dependent: :destroy`.

**Aturan balasan.** Balasan ke sebuah balasan dinaikkan oleh controller ke komentar utama induknya, sehingga hanya ada dua tingkat.

**Rute.**
- Publik: `resources :products, only: %i[index show] do resources :comments, only: :create end`.
- Admin: `resources :comments, only: :index` dengan aksi member `patch :hide` dan `patch :restore` (nama aksi berbahasa Inggris mengikuti `ship`, `complete`, `cancel`).

**Controller.**
- `CommentsController#create`: wajib login (perilaku bawaan `Authentication`), membuat komentar atas nama `current_user` untuk produk dari URL, lalu `redirect_to product_path(product, anchor: "diskusi")` dengan notice atau pesan kesalahan. Memakai `rate_limit` bawaan Rails 8 (mis. 10 komentar per menit per pengguna).
- `Admin::CommentsController` mewarisi `Admin::BaseController`: `index` (terbaru dulu, dengan kaminari, filter opsional `?status=`), `hide`, `restore`.

**Tampilan.**
- Halaman produk: bagian "Diskusi (N)" di bawah deskripsi, N menghitung komentar `tampil`. Formulir hanya untuk yang login; yang belum login melihat ajakan masuk. Komentar utama dengan balasannya di bawah, dimuat dengan `includes(:user, replies: :user)` supaya tidak terjadi N+1.
- Komentar `disembunyikan` tampil sebagai "(komentar disembunyikan oleh admin)" tanpa isi asli. Balasannya tetap terlihat (keputusanku, agar percakapan tidak putus; admin bisa menyembunyikan tiap balasan satu per satu).
- Isi komentar dirender dengan escape (jangan pernah `raw` atau `html_safe`), memakai `simple_format` agar baris baru terjaga.
- Admin: halaman "Diskusi" di sidebar (ikon `chat-dots`), daftar komentar dengan produk, penulis, isi, status, dan tombol Sembunyikan/Tampilkan.

**Pengujian (minitest, sesuai folder `test/` yang ada).** Model: validasi body, aturan induk (produk sama, hanya satu tingkat). Controller: pengunjung tanpa login ditolak, pengguna login bisa membuat, balasan ke balasan masuk ke induk utama, non-admin tidak bisa `hide`/`restore`. Tampilan: komentar tersembunyi tidak menampilkan isinya.

## Pilihan saya (silakan dikoreksi)
- Nama status Indonesia, nama aksi admin Inggris.
- Balasan tetap terlihat saat induknya disembunyikan.
- Batas 1000 karakter dan 10 komentar per menit.
- Tanpa badge di sidebar (tidak ada antrean persetujuan).

## Diserahkan ke pembangun
Nama persis helper, kelas CSS, dan ikon mengikuti gaya yang sudah ada di tampilan. Cara membuat fixture dan sesi login untuk tes mengikuti `test/test_helpers`.
