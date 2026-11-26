# Rating Produk dari Pembeli — Rencana Belajar & Implementasi

> **Untuk pelaksana:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans. Rencana ini ditulis sebagai panduan belajar: **pemilik proyek yang mengetik kodenya sendiri**, Claude menjelaskan dan membantu kalau macet. Langkah memakai checkbox (`- [ ]`).

**Tujuan:** Halaman produk menampilkan rata-rata bintang dan jumlah rating, dan hanya user yang punya pesanan `completed` berisi produk itu yang bisa memberi atau mengubah rating (1–5).

**Arsitektur:** Model `Rating` (user, product, stars) dengan indeks unik `[user_id, product_id]`. Aturan "sudah membeli" ada di satu method, `User#sudah_membeli?(product)`, yang dipakai validasi model dan tampilan. Rata-rata dihitung saat halaman dibuka. Pola mengikuti `Favorite` (model kecil) dan `CommentsController` (redirect dengan notice/alert, `rate_limit`).

**Tech Stack:** Rails 8.1, PostgreSQL, minitest, Bootstrap + `theme.css` yang sudah ada.

**Spec:** [docs/superpowers/specs/2026-11-26-product-ratings-design.md](../specs/2026-11-26-product-ratings-design.md)

## Global Constraints

- Tabel/model `ratings`/`Rating`; kolom `user_id`, `product_id` (wajib), `stars` (integer, wajib). Indeks unik `[user_id, product_id]`.
- `stars` bilangan bulat **1–5**. Satu rating per user per produk.
- Boleh memberi rating hanya bila user punya `Order` berstatus **`completed`** yang berisi produk itu. Status lain (`pending`, `paid`, `shipped`, `canceled`) tidak cukup.
- Server yang menolak (validasi model), bukan hanya form yang disembunyikan.
- User boleh mengubah rating; tidak ada hapus. Tidak ada teks ulasan, label "Verified", atau kolom cache rata-rata.
- Rute tunggal: `resources :products do resource :rating, only: %i[create update] end`. Wajib login.
- Teks untuk pengguna berbahasa Indonesia; komentar kode berbahasa Indonesia (gaya proyek).

## Review Focus

Hal yang tersirat dari spec tapi mudah terlewat; tiap baris punya tesnya di task yang disebut.

1. Pesanan `completed` yang berisi produk **lain** tidak membuka rating produk ini (Task 1).
2. Pesanan `completed` milik **user lain** berisi produk ini tidak membuka rating untuk user ini (Task 1).
3. `stars` bernilai `"4.5"`, `"abc"`, `0`, `6`, atau kosong ditolak dan tidak ada rating tersimpan (Task 2 dan 3).
4. Kiriman kedua dari user yang sudah punya rating tidak membuat baris kedua; user tidak bisa mengubah rating milik orang lain (Task 3).
5. Produk tanpa rating menampilkan "Belum ada rating", bukan error atau "NaN" (Task 4).

## Struktur File

| File | Tugas |
|------|-------|
| `test/test_helpers/pesanan_test_helper.rb` (baru), `test/test_helper.rb` (ubah) | Helper tes `buat_pesanan` |
| `app/models/user.rb` (ubah) | `sudah_membeli?`, `has_many :ratings` |
| `db/migrate/*_create_ratings.rb`, `app/models/rating.rb` (baru) | Tabel dan model |
| `app/models/product.rb` (ubah) | `has_many :ratings`, `rata_rata_rating`, `jumlah_rating` |
| `config/routes.rb` (ubah), `app/controllers/ratings_controller.rb` (baru) | Simpan dan ubah rating |
| `app/helpers/ratings_helper.rb`, `app/views/ratings/_ringkasan.html.erb`, `_section.html.erb`, `_form.html.erb` (baru) | Tampilan |
| `app/controllers/products_controller.rb`, `app/views/products/show.html.erb` (ubah) | Menyiapkan dan memasang tampilan |
| `test/models/user_test.rb` (ubah), `test/models/rating_test.rb`, `test/controllers/ratings_controller_test.rb`, `test/controllers/product_ratings_test.rb` (baru) | Tes |

Jalankan tes per file: `bin/rails test <file>`. Fixture global sudah dimatikan; tes membuat datanya sendiri di `setup`.

---

### Task 1: Aturan "sudah membeli" di `User`

**Konsep:** *Query dengan join dan `exists?`*, serta kenapa aturan penting diletakkan di satu method yang diuji tersendiri.

**Files:**
- Create: `test/test_helpers/pesanan_test_helper.rb`
- Modify: `test/test_helper.rb`, `app/models/user.rb`, `test/models/user_test.rb`

**Interfaces:**
- Produces: `PesananTestHelper#buat_pesanan(user:, produk:, status: :completed) -> Order` (membuat `Order` dengan semua kolom alamat terisi dan satu `OrderItem` untuk `produk`, tersedia di semua `ActiveSupport::TestCase`); `User#sudah_membeli?(product) -> true/false`.

- [ ] **Step 1: Buat cabang dan catat kondisi awal.** `git checkout -b fitur/rating-produk`, lalu jalankan `bin/rails test` dan tuliskan jumlah failure dan error-nya. Angka ini dipakai sebagai pembanding di Task 4 Step 9.
- [ ] **Step 2: Tulis helper tes** `buat_pesanan` di modul `PesananTestHelper` (`test/test_helpers/pesanan_test_helper.rb`). `Order` mewajibkan `recipient_name`, `phone`, `street`, `city`, `province`, `postal_code`; `OrderItem` mewajibkan `product_name`, `quantity` > 0, `unit_price` >= 0. Sertakan modul itu di `ActiveSupport::TestCase` pada `test/test_helper.rb` (`require_relative` + `include`).
- [ ] **Step 3: Tulis tes yang gagal** di akhir `test/models/user_test.rb`, membuat datanya sendiri (dua `User`, dua `Product`). Nama tes dan asersi:
  - `"sudah_membeli? true untuk pesanan completed berisi produk itu"` → `assert user.sudah_membeli?(produk)`
  - `"sudah_membeli? false untuk status selain completed"` → loop `%i[pending paid shipped canceled]`, tiap status `refute`
  - `"sudah_membeli? false untuk produk lain"` → pesanan completed berisi produk A, `refute user.sudah_membeli?(produk_b)`
  - `"sudah_membeli? false untuk pesanan milik user lain"` → pesanan completed milik user lain, `refute user.sudah_membeli?(produk)`
- [ ] **Step 4: Jalankan, pastikan gagal.** `bin/rails test test/models/user_test.rb` → `NoMethodError: sudah_membeli?`.
- [ ] **Step 5: Implementasikan `User#sudah_membeli?(product)`** di `app/models/user.rb`: `orders.completed.joins(:order_items).exists?(order_items: { product_id: product.id })`.
- [ ] **Step 6: Jalankan lagi** → hijau.
- [ ] **Step 7: Commit.** `git add -A && git commit -m "feat: User#sudah_membeli? dari pesanan completed"`

---

### Task 2: Tabel dan model `Rating`

**Konsep:** *Validasi kustom*, *validasi keunikan dengan scope* (sama dengan `Favorite`), dan *agregasi* (`average`).

**Files:**
- Create: `db/migrate/<timestamp>_create_ratings.rb`, `app/models/rating.rb`, `test/models/rating_test.rb`
- Modify: `app/models/product.rb`, `app/models/user.rb`

**Interfaces:**
- Consumes: `User#sudah_membeli?`, `buat_pesanan` (Task 1).
- Produces: `Rating` (`belongs_to :user`, `:product`; `stars`); `User#ratings`, `Product#ratings`; `Product#rata_rata_rating -> Float | nil` (satu desimal, `nil` bila belum ada rating); `Product#jumlah_rating -> Integer`.

- [ ] **Step 1: Generate model tanpa fixture.** `bin/rails g model Rating user:references product:references stars:integer --no-fixture`
- [ ] **Step 2: Rapikan migrasi.** `stars` menjadi `null: false`, dan tambah `add_index :ratings, [:user_id, :product_id], unique: true` setelah `create_table` (lihat `create_favorites.rb`).
- [ ] **Step 3: Migrasikan.** `bin/rails db:migrate`. Diharapkan `== CreateRatings: migrated` dan `create_table "ratings"` di `db/schema.rb`.
- [ ] **Step 4: Tulis tes yang gagal** di `test/models/rating_test.rb`. `setup` membuat `@user`, `@produk`, dan pesanan completed untuk keduanya; helper `buat(**atribut)` mengembalikan `Rating.new` valid (stars 5). Tes:
  - `"valid untuk pembeli completed"` → `assert buat.valid?`
  - `"stars harus bilangan bulat 1 sampai 5"` → 1 dan 5 valid; `0`, `6`, `nil`, `"4.5"`, `"abc"` tidak valid
  - `"ditolak bila belum membeli"` → user tanpa pesanan: `refute valid?`, `errors[:base]` terisi
  - `"ditolak bila pesanan belum completed"` → pesanan `shipped`: `refute valid?`
  - `"satu rating per user per produk"` → rating pertama disimpan, `buat` kedua `refute valid?`
  - `"rata_rata_rating dan jumlah_rating"` → dua user completed memberi 5 dan 4: `assert_equal 4.5, @produk.rata_rata_rating`, `assert_equal 2, @produk.jumlah_rating`
  - `"rata_rata_rating nil bila belum ada rating"` → `assert_nil @produk.rata_rata_rating`, `assert_equal 0, @produk.jumlah_rating`
- [ ] **Step 5: Jalankan, pastikan gagal.**
- [ ] **Step 6: Isi `Rating`** di `app/models/rating.rb`: `belongs_to :user`, `belongs_to :product`; `validates :stars, numericality: { only_integer: true, in: 1..5 }`; `validates :user_id, uniqueness: { scope: :product_id, message: "sudah memberi rating untuk produk ini" }`; validasi kustom privat `harus_sudah_membeli` yang menambah error pada `:base` ("Rating hanya untuk pembeli yang pesanannya sudah selesai") bila `user` dan `product` ada tetapi `!user.sudah_membeli?(product)`. `numericality` membaca nilai mentah, itulah yang menolak `"4.5"`.
- [ ] **Step 7: Hubungkan.** `has_many :ratings, dependent: :destroy` di `User` dan `Product`; di `Product` tambah `rata_rata_rating` (`ratings.average(:stars)&.round(1)&.to_f`) dan `jumlah_rating` (`ratings.count`).
- [ ] **Step 8: Jalankan lagi** → hijau.
- [ ] **Step 9: Coba di console** (`bin/rails console`): `Rating.new(user:, product:, stars: 5).valid?` lalu `.errors.full_messages` untuk user yang belum membeli. Ini cara tercepat memahami validasi kustom.
- [ ] **Step 10: Commit.** `git add -A && git commit -m "feat: model Rating dengan validasi pembeli completed"`

---

### Task 3: Rute dan `RatingsController`

**Konsep:** *Resource tunggal* (`resource`, bukan `resources`: tidak ada id rating di URL), *scoping lewat `current_user`* supaya tidak bisa menyentuh data orang lain, `params.expect`, dan `rate_limit`.

**Files:**
- Modify: `config/routes.rb`
- Create: `app/controllers/ratings_controller.rb`, `test/controllers/ratings_controller_test.rb`

**Interfaces:**
- Consumes: `Rating`, `User#ratings`, `buat_pesanan`, `sign_in_as`.
- Produces: `POST` dan `PATCH` ke `product_rating_path(product)` dengan parameter `rating[stars]`. Sukses atau gagal selalu redirect ke `product_path(product, anchor: "rating")` dengan `notice` atau `alert`.

- [ ] **Step 1: Tulis tes yang gagal** (`ActionDispatch::IntegrationTest`; `setup` membuat user, produk, pesanan completed). Kirim dengan `post product_rating_url(@produk), params: { rating: { stars: 4 } }`. Tes:
  - `"tamu diarahkan ke login dan tidak membuat rating"` → `assert_redirected_to new_session_url`, `Rating.count` tetap
  - `"pembeli completed membuat rating"` → `assert_difference "Rating.count", 1`, redirect ke `product_url(@produk, anchor: "rating")`, `Rating.last.stars == 4` dan milik `@user`
  - `"user yang belum membeli ditolak server"` → `Rating.count` tetap, `flash[:alert]` terisi
  - `"stars tidak valid ditolak"` → untuk `"0"`, `"6"`, `"4.5"`, `"abc"`, `""`: `Rating.count` tetap, `flash[:alert]` terisi
  - `"kiriman kedua tidak membuat rating baru"` → `post` dua kali, `Rating.count` naik hanya 1, `flash[:alert]` terisi pada kiriman kedua
  - `"pembeli mengubah rating sendiri"` → `patch product_rating_url(@produk), params: { rating: { stars: 2 } }`, `assert_equal 2, @user.ratings.first.stars`
  - `"patch tanpa rating sebelumnya memberi pesan"` → `flash[:alert]` terisi, `Rating.count` nol
  - `"tidak bisa mengubah rating orang lain"` → user kedua (completed) sudah punya rating 5; user pertama `patch` dengan stars 1; rating user kedua tetap 5
- [ ] **Step 2: Jalankan, pastikan gagal** (routing error).
- [ ] **Step 3: Rute.** Di blok `resources :products` pada `config/routes.rb`, tambahkan `resource :rating, only: %i[create update]`. Cek `bin/rails routes -g rating` memuat `POST` dan `PATCH /products/:product_id/rating`.
- [ ] **Step 4: Tulis `RatingsController`** dengan `create` dan `update`. `create`: `produk = Product.find(params[:product_id])`, `rating = current_user.ratings.new(product: produk, stars: nilai)`; `update`: `rating = current_user.ratings.find_by(product: produk)`, bila `nil` redirect dengan alert "Anda belum memberi rating untuk produk ini."; selainnya `rating.update(stars: nilai)`. `nilai` dari `params.expect(rating: [:stars])[:stars]` (nilai mentah, jangan di-`to_i`, supaya `"4.5"` tetap ditolak). Helper privat `ke_rating(produk, **pesan)` meredirect ke `product_path(produk, anchor: "rating")`. Notice "Rating tersimpan." atau alert dari `errors.full_messages.to_sentence`. Tambah `rate_limit to: 10, within: 1.minute, only: %i[create update], by: -> { current_user.id }` (polanya sama dengan `CommentsController`).
- [ ] **Step 5: Jalankan** `bin/rails test test/controllers/ratings_controller_test.rb` → hijau.
- [ ] **Step 6: Commit.** `git add -A && git commit -m "feat: pembeli dapat memberi dan mengubah rating"`

---

### Task 4: Tampilan rating di halaman produk

**Konsep:** *Partial*, *helper view*, *radio button di `form_with`*, dan membaca tampilan dengan `assert_select`.

**Files:**
- Create: `app/helpers/ratings_helper.rb`, `app/views/ratings/_ringkasan.html.erb`, `_section.html.erb`, `_form.html.erb`, `test/controllers/product_ratings_test.rb`
- Modify: `app/controllers/products_controller.rb`, `app/views/products/show.html.erb`

**Interfaces:**
- Consumes: `Product#rata_rata_rating`, `#jumlah_rating`, `User#sudah_membeli?`, `product_rating_path`.
- Produces: `RatingsHelper#bintang(nilai) -> String` (mis. `bintang(4) == "★★★★☆"`, `nil` dianggap 0); di `ProductsController#show`: `@boleh_menilai` (true/false; false untuk tamu) dan `@rating_saya` (`Rating` milik `current_user` untuk produk ini, atau `nil`). `render "ratings/ringkasan", product:` dan `render "ratings/section", product:, boleh_menilai:, rating_saya:`; wadah dengan `id="rating"`.

- [ ] **Step 1: Tulis tes yang gagal** (`ActionDispatch::IntegrationTest`, `get product_url(@produk)`). Tes:
  - `"produk tanpa rating menampilkan Belum ada rating"` → `assert_select` memuat teks itu, status 200
  - `"tamu tidak melihat form rating"` → `assert_select "form[action=?]", product_rating_path(@produk), count: 0`
  - `"user yang belum membeli tidak melihat form, ada keterangan"` → form `count: 0` dan teks "Rating dibuka setelah pesanan selesai"
  - `"pesanan shipped belum membuka form"` → form `count: 0`
  - `"pembeli completed melihat form"` → `assert_select "form[action=?]", product_rating_path(@produk)` dan lima `input[type=radio][name='rating[stars]']`
  - `"rating sendiri terpilih dan rata-rata tampil"` → dua user completed memberi 5 dan 4 (disimpan lewat model); halaman menampilkan "4,5" dan "2 rating"; untuk user pertama, `input[type=radio][value='5'][checked]`
  - Tes helper `bintang`: `bintang(4) == "★★★★☆"`, `bintang(nil) == "☆☆☆☆☆"` (di `test/helpers/ratings_helper_test.rb`, `ActionView::TestCase`).
- [ ] **Step 2: Jalankan, pastikan gagal.**
- [ ] **Step 3: Helper `bintang(nilai)`** di `RatingsHelper`: `nilai.to_i.clamp(0, 5)` jumlah `"★"` diikuti sisanya `"☆"`.
- [ ] **Step 4: Siapkan data di `ProductsController#show`.** `@boleh_menilai = current_user&.sudah_membeli?(@product) || false`, `@rating_saya = current_user&.ratings&.find_by(product: @product)`.
- [ ] **Step 5: Tulis partial.** `_ringkasan`: bila `product.jumlah_rating.zero?` tampilkan "Belum ada rating"; selainnya `bintang(product.rata_rata_rating.round)`, angka dengan koma desimal (`number_with_precision(..., precision: 1, separator: ",")`), dan "N rating". `_section` (`<section id="rating" class="mt-5 pt-4 border-top">`): judul, `_ringkasan`, lalu tiga kemungkinan: `boleh_menilai` → `_form`; user login tapi belum boleh → "Rating dibuka setelah pesanan selesai."; tamu → tautan "Masuk" ke `new_session_path`. `_form`: `form_with model: Rating.new, url: product_rating_path(product), method: (rating_saya ? :patch : :post)` dengan lima radio `form.radio_button :stars, n` (yang sama dengan `rating_saya&.stars` ditandai `checked`), label `bintang(n)`, tombol "Kirim" atau "Ubah". Ikuti gaya `comments/_form.html.erb`.
- [ ] **Step 6: Pasang di `products/show.html.erb`.** `_ringkasan` di kolom kanan tepat di bawah `<h1>`, dan `render "ratings/section", ...` tepat di atas `render "comments/section"`.
- [ ] **Step 7: Jalankan tes** `bin/rails test test/controllers/product_ratings_test.rb test/helpers/ratings_helper_test.rb` → hijau.
- [ ] **Step 8: Cek di browser.** `bin/dev`, masuk sebagai pembeli dengan pesanan `completed`, beri rating lalu ubah. Cek juga sebagai tamu dan sebagai user tanpa pesanan selesai. Lapor ke Claude kalau tampilannya aneh di layar HP.
- [ ] **Step 9: Jalankan seluruh tes** `bin/rails test`. Syarat selesai: tidak ada kegagalan baru dibanding sebelum fitur ini (catat angkanya di awal Task 1 dengan menjalankan `bin/rails test` di cabang baru).
- [ ] **Step 10: Commit.** `git add -A && git commit -m "feat: tampilkan dan isi rating di halaman produk"`
