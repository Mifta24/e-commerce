# Rating Produk dari Pembeli — Desain Singkat

Tanggal: 2026-11-26. Status: menunggu persetujuan.

## Tujuan dan alasan
Calon pembeli ingin tahu seberapa puas pembeli sebelumnya. Halaman produk menampilkan rata-rata bintang dan jumlah rating. Hanya user yang pesanannya sudah `completed` dan berisi produk itu yang boleh memberi rating, supaya angkanya bisa dipercaya. Fitur ini juga bahan belajar Rails untuk pemilik proyek, jadi polanya harus mudah diikuti dan mirip kode yang sudah ada (`Favorite`, `CommentsController`).

## Bukan tujuan
- Teks ulasan (sudah ada fitur komentar).
- Menghapus rating.
- Label "Verified Purchase" (tidak perlu: semua rating pasti dari pembeli).
- Counter cache rata-rata (ditambahkan nanti kalau daftar produk perlu menampilkannya).
- Rating per pesanan: user yang membeli produk yang sama dua kali tetap punya satu rating per produk.

## Anti-tujuan (dianggap gagal walau secara teknis jalan)
- User yang belum punya pesanan `completed` berisi produk itu bisa menyimpan rating, misalnya lewat request manual tanpa form.
- Pesanan `pending`, `paid`, `shipped`, atau `canceled` dianggap sudah membeli.
- Satu user punya lebih dari satu rating untuk produk yang sama.
- Nilai di luar 1–5 tersimpan.

## Pendekatan yang dipertimbangkan
1. **Model `Rating` sendiri (user, product, bintang 1–5) (dipilih pemilik).** Aturan "sudah beli" dicek lewat validasi model. Satu tempat, mudah dipelajari, pola sama dengan `Favorite`.
2. Rating menempel ke `OrderItem`. Ditolak: bukti beli tertanam di struktur data, tetapi pembelian ulang menghasilkan dua baris yang bisa dinilai dan query rata-rata per produk lebih berbelit.
3. Kolom `rating` di `Comment`. Ditolak: mencampur diskusi berbalas dan bermoderasi dengan satu nilai per user per produk.

## Keputusan pemilik
- Verified = pesanan berstatus `completed`.
- Hanya pembeli `completed` yang boleh memberi rating (form disembunyikan untuk yang lain dan server menolak kiriman manual).

## Desain (pilihan saya, belum disebut pemilik secara rinci)

**Data.** Tabel `ratings`: `user_id` (wajib), `product_id` (wajib), `stars` (integer, wajib), timestamps. Indeks unik `[user_id, product_id]` dan indeks `product_id`.

**Model `Rating`.**
- `belongs_to :user`, `belongs_to :product`.
- Validasi `stars` berupa bilangan bulat 1–5.
- Validasi keunikan `user_id` dengan scope `product_id` (pesan Indonesia, mengikuti `Favorite`).
- Validasi khusus: user harus punya pesanan `completed` yang berisi produk ini (`Order.completed` digabung dengan `order_items`).
- `Product` dan `User`: `has_many :ratings, dependent: :destroy`.
- Method di `Product` untuk rata-rata (`ratings.average(:stars)`) dan jumlah rating, dihitung saat halaman dibuka.
- Method di `User` atau `Product` untuk menjawab "apakah user ini boleh memberi rating produk ini?". Dipakai bersama oleh tampilan dan validasi supaya aturannya tidak ganda.

**Rute.** `resources :products do resource :rating, only: %i[create update] end`. Satu rating per user per produk, jadi tunggal (`resource`).

**Controller `RatingsController`.** Wajib login (mengikuti `Authentication` yang sudah ada). `create` dan `update` mencari rating milik `current_user` untuk produk itu. Gagal validasi: redirect ke halaman produk dengan pesan error. `rate_limit` seperti `CommentsController`.

**Tampilan di `products/show`.**
- Semua orang melihat rata-rata dan jumlah rating ("Belum ada rating" kalau kosong).
- Pembeli `completed`: form bintang 1–5, terisi nilai lama kalau sudah pernah memberi (tombol "Ubah").
- User login yang belum beli: tidak ada form, boleh ada keterangan singkat "Rating dibuka setelah pesanan selesai".
- Pengunjung belum login: tidak ada form.

**Pengujian.** Tes model: lolos untuk pembeli `completed`; ditolak untuk status lain, untuk produk yang tidak ada di pesanan itu, bintang di luar 1–5, dan duplikat. Tes controller: wajib login, user tak berhak ditolak server, ubah rating berhasil. Tes tampilan: form muncul hanya untuk pembeli yang berhak.

## Cara kerja
Dikerjakan bertahap sambil belajar: pemilik menulis kode, saya menjelaskan tiap langkah, mengecek, dan menjalankan tes. Urutan: migrasi → model + tes → controller + rute → tampilan.

## Diserahkan ke pembuat
Nama kolom dan method persisnya, teks pesan error, tampilan bintang (HTML/CSS biasa atau karakter ★), dan letak bagian rating di halaman produk (dekat nama produk atau di atas bagian diskusi).
