# Diskusi Produk dengan Moderasi — Rencana Belajar & Implementasi

> **Untuk pelaksana:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans. Rencana ini ditulis sebagai panduan belajar: **pemilik proyek yang mengetik kodenya sendiri**, Claude menjelaskan dan membantu kalau macet. Langkah memakai checkbox (`- [ ]`).

**Tujuan:** Halaman produk punya bagian diskusi (tanya-jawab antar pembeli, balasan satu tingkat) dan admin bisa menyembunyikan komentar yang melanggar.

**Arsitektur:** Satu tabel `comments` dengan `parent_id` yang merujuk ke tabelnya sendiri. Komentar langsung tampil; admin mengubah `status` menjadi `disembunyikan`. Pola mengikuti `Favorite` (model + controller kecil) dan `Admin::Customers` / `Admin::Orders` (daftar admin + aksi member).

**Tech Stack:** Rails 8.1, PostgreSQL, minitest, kaminari, Bootstrap + `theme.css` yang sudah ada.

**Spec:** [docs/superpowers/specs/2026-11-25-product-discussions-design.md](../specs/2026-11-25-product-discussions-design.md)

## Global Constraints

- Nama: tabel/model `comments`/`Comment`; kolom `user_id`, `product_id`, `parent_id` (boleh kosong), `body` (text, wajib), `status` (integer, default 0).
- `enum :status, { tampil: 0, disembunyikan: 1 }`. Aksi admin bernama `hide` dan `restore` (Inggris, mengikuti `ship`/`complete`/`cancel`).
- `body` wajib dan maksimal **1000** karakter. Batas tulis: **10 komentar per menit** (`rate_limit`).
- Balasan hanya satu tingkat: induk harus komentar utama dan satu produk yang sama. Balasan ke balasan dinaikkan oleh controller ke komentar utama.
- Yang menulis harus login. Membaca terbuka untuk umum.
- Isi komentar **selalu di-escape**; dilarang `raw` atau `html_safe`.
- Teks untuk pengguna berbahasa Indonesia; komentar kode berbahasa Indonesia (gaya proyek).
- Bukan tujuan: edit/hapus oleh penulis, tombol "Laporkan", notifikasi, paginasi di halaman produk, counter cache, badge sidebar.

## Review Focus

Hal yang disebut spec secara tersirat tapi mudah terlewat; tiap baris punya tesnya di task yang disebut.

1. `body` kosong atau hanya spasi harus ditolak (Task 1).
2. `body` berisi HTML seperti `<script>` harus tampil sebagai teks, bukan dijalankan (Task 3).
3. `parent_id` menunjuk komentar milik produk lain, id yang tidak ada, atau teks bukan angka: komentar tidak dibuat dan pengguna dapat pesan jelas (Task 2).
4. Komentar yang disembunyikan: isinya tidak boleh ada di HTML publik, tetapi admin tetap bisa membacanya (Task 3 dan 4).
5. Tamu atau pelanggan biasa memanggil `hide`/`restore` harus ditolak dan status tidak berubah (Task 4).

## Struktur File

| File | Tugas |
|------|-------|
| `db/migrate/*_create_comments.rb` (baru) | Membuat tabel |
| `app/models/comment.rb` (baru) | Asosiasi, enum, validasi, scope |
| `app/models/product.rb`, `app/models/user.rb` (ubah) | `has_many :comments, dependent: :destroy` |
| `app/controllers/comments_controller.rb` (baru) | `create` untuk pembeli |
| `app/controllers/products_controller.rb` (ubah) | Menyiapkan data diskusi di `show` |
| `app/views/comments/_section.html.erb`, `_comment.html.erb`, `_form.html.erb` (baru) | Tampilan diskusi |
| `app/views/products/show.html.erb` (ubah) | Memanggil `comments/section` |
| `app/controllers/admin/comments_controller.rb` + `app/views/admin/comments/index.html.erb` (baru) | Antrean moderasi |
| `app/views/admin/shared/_sidebar.html.erb`, `config/routes.rb` (ubah) | Menu dan rute |
| `test/models/comment_test.rb`, `test/controllers/comments_controller_test.rb`, `test/controllers/product_discussions_test.rb`, `test/controllers/admin/comments_controller_test.rb` (baru) | Tes |

Jalankan tes fitur ini dengan `bin/rails test <file>` per file (lihat Task 0 kenapa).

---

### Task 0: Siapkan cabang dan fondasi tes

**Konsep:** Sebelum menulis fitur, pastikan tes bisa dipakai. Saat ini `bin/rails test` gagal total (52 error) karena `fixtures :all` memuat fixture bawaan scaffold yang usang: `carts.yml` punya token kembar `MyString` dan `users.yml` tidak punya kolom `name` yang wajib. Tes yang sudah kamu tulis sendiri (mis. `ProductsControllerTest`) membuat datanya di `setup`, tanpa fixture. Kita ikuti gaya itu.

**Files:**
- Modify: `test/test_helper.rb`

- [ ] **Step 1: Buat cabang.** `git checkout -b fitur/diskusi-produk`
- [ ] **Step 2: Matikan fixture global.** Di `test/test_helper.rb`, jadikan baris `fixtures :all` komentar, dengan satu baris komentar alasannya (fixture scaffold usang; tes membuat datanya sendiri).
- [ ] **Step 3: Catat kondisi awal.** Jalankan `bin/rails test`. Hasil yang diharapkan: tidak lagi 52 error; sisanya sekitar 4 failure + 32 error dari tes scaffold kosong milik fitur lain (Addresses, Carts, Categories, Passwords, Sessions, Home, Products). Tuliskan angkanya. **Syarat selesai fitur: angka ini tidak bertambah.** Kalau hasilmu sangat berbeda, kabari Claude.
- [ ] **Step 4: Commit.** `git add test/test_helper.rb && git commit -m "test: matikan fixtures :all yang usang"`

---

### Task 1: Tabel dan model `Comment`

**Konsep:** *Asosiasi ke tabel sendiri* (`parent`/`replies`), *enum*, dan *validasi kustom*. Ingat penjelasan `parent_id`: kosong = komentar utama, berisi id = balasan.

**Files:**
- Create: `db/migrate/<timestamp>_create_comments.rb`, `app/models/comment.rb`
- Modify: `app/models/product.rb`, `app/models/user.rb`
- Test: `test/models/comment_test.rb`

**Interfaces:**
- Produces: `Comment` dengan `belongs_to :user`, `:product`, `:parent` (optional), `has_many :replies` (urut `created_at, id`), `enum :status` (`tampil?`, `disembunyikan?`, `tampil!`, `disembunyikan!`, scope `Comment.tampil`), scope `Comment.utama`, konstanta `Comment::MAX_BODY = 1000`; `Product#comments` dan `User#comments`.

- [ ] **Step 1: Generate model tanpa fixture.**
  `bin/rails g model Comment user:references product:references parent:references body:text status:integer --no-fixture`
- [ ] **Step 2: Rapikan migrasi.** Ubah `parent` menjadi `t.references :parent, foreign_key: { to_table: :comments }` (boleh kosong; `to_table` karena tidak ada tabel `parents`), `body` menjadi `null: false`, `status` menjadi `null: false, default: 0`, dan tambah `add_index :comments, [:product_id, :status]` setelah `create_table`.
- [ ] **Step 3: Migrasikan.** `bin/rails db:migrate`. Diharapkan: `== CreateComments: migrated`, dan `db/schema.rb` memuat `create_table "comments"` dengan tiga foreign key.
- [ ] **Step 4: Tulis tes yang gagal** di `test/models/comment_test.rb`. `setup` membuat satu `User` (`name`, `email_address`, `password`), dua `Product` (`name`, `price`, `stock`), dan helper `buat(**atribut)` yang mengembalikan `Comment.new` valid (user, product pertama, body "Ukurannya pas?") yang bisa ditimpa. Nama tes dan asersi:
  - `"valid dengan atribut lengkap"` → `assert buat.valid?`
  - `"body wajib, termasuk yang hanya spasi"` → `refute buat(body: "").valid?` dan `refute buat(body: "   ").valid?`
  - `"body maksimal 1000 karakter"` → 1000 karakter valid, `"a" * 1001` tidak valid
  - `"status awal tampil"` → `assert buat.tampil?`
  - `"balasan harus satu produk dengan induknya"` → induk di produk A, balasan di produk B → `refute valid?` dan `errors[:parent]` terisi
  - `"balasan ke balasan ditolak"` → induk yang sendiri punya `parent` → `refute valid?`
  - `"scope utama hanya komentar tanpa induk"` → `assert_equal [utama], Comment.utama.to_a`
  - `"menghapus induk menghapus balasannya"` → `assert_difference "Comment.count", -2 do utama.destroy end`
  - `"menghapus produk menghapus komentarnya"` → `assert_difference "Comment.count", -1 do @produk.destroy end`
- [ ] **Step 5: Jalankan, pastikan gagal.** `bin/rails test test/models/comment_test.rb`. Diharapkan: gagal (validasi belum ada; `Product#comments` belum ada).
- [ ] **Step 6: Isi `Comment`** di `app/models/comment.rb`: asosiasi seperti di Interfaces (`replies` dengan `class_name: "Comment"`, `foreign_key: :parent_id`, `inverse_of: :parent`, `dependent: :destroy`), `enum :status`, `validates :body, presence: true, length: { maximum: MAX_BODY }`, scope `utama` (`where(parent_id: nil)`), dan validasi kustom privat `parent_harus_valid` yang menambah error pada `:parent` bila produk induk berbeda atau induk itu sendiri punya `parent_id`.
- [ ] **Step 7: Hubungkan.** Tambahkan `has_many :comments, dependent: :destroy` di `Product` dan `User`.
- [ ] **Step 8: Jalankan lagi.** `bin/rails test test/models/comment_test.rb` → semua hijau.
- [ ] **Step 9: Coba di console** (`bin/rails console`): buat satu komentar dan satu balasan, lalu cek `komentar.replies` dan `balasan.parent`. Ini cara paling cepat memahami asosiasinya.
- [ ] **Step 10: Commit.** `git add -A && git commit -m "feat: model Comment dengan balasan satu tingkat"`

---

### Task 2: Rute dan `CommentsController#create`

**Konsep:** *Nested routes* (komentar "milik" produk), *autentikasi* (`ApplicationController` sudah menyertakan `Authentication`, jadi tamu otomatis diarahkan ke login), *strong params* gaya Rails 8 (`params.expect`), dan *rate limit* (lihat `SessionsController` untuk polanya).

**Files:**
- Modify: `config/routes.rb`
- Create: `app/controllers/comments_controller.rb`
- Test: `test/controllers/comments_controller_test.rb`

**Interfaces:**
- Consumes: `Comment`, `Product#comments` (Task 1).
- Produces: route `product_comments_path(product)` (POST); setelah sukses atau gagal, redirect ke `product_path(product, anchor: "diskusi")` dengan `notice`/`alert`. Form mengirim `comment[body]` dan `comment[parent_id]` (opsional).

- [ ] **Step 1: Tulis tes yang gagal.** `ActionDispatch::IntegrationTest`; `setup` membuat produk dan pengguna, memakai `sign_in_as(user)` dari `SessionTestHelper` bila perlu. Tes (kirim dengan `post product_comments_url(@produk), params: { comment: { body: "...", parent_id: ... } }`):
  - `"tamu diarahkan ke login dan tidak membuat komentar"` → `assert_redirected_to new_session_url`, `Comment.count` tetap
  - `"pembeli login membuat komentar utama"` → `assert_difference "Comment.count", 1`; `assert_redirected_to product_url(@produk, anchor: "diskusi")`; penulisnya `current user`
  - `"body kosong tidak membuat komentar dan memberi pesan"` → `Comment.count` tetap; `flash[:alert]` terisi
  - `"balasan ke balasan masuk ke komentar utama"` → `assert_equal utama, Comment.order(:id).last.parent`
  - `"parent_id dari produk lain ditolak"`, `"parent_id yang tidak ada ditolak"`, dan `"parent_id bukan angka ditolak"` (`"abc"`) → `Comment.count` tetap dan `flash[:alert]` terisi (komentar **tidak** boleh diam-diam menjadi komentar utama)
- [ ] **Step 2: Jalankan, pastikan gagal** (`NoMethodError`/`routing error`).
- [ ] **Step 3: Rute.** Ubah `resources :products, only: %i[index show]` di `config/routes.rb` menjadi memuat blok `resources :comments, only: :create`. Cek `bin/rails routes -g comments` memuat `POST /products/:product_id/comments`.
- [ ] **Step 4: Tulis `CommentsController#create`** (`Product.find(params[:product_id])`; ambil `params.expect(comment: %i[body parent_id])`). Cari induk dengan `@produk.comments.find_by(id: ...)` hanya bila `parent_id` diisi; jika diisi tapi tidak ketemu, redirect dengan alert "Komentar yang dibalas tidak ditemukan." Jika induk itu balasan, pakai `induk.parent`. Simpan dengan `user: current_user`; sukses → notice "Komentar terkirim.", gagal → alert dari `errors.full_messages.to_sentence`. Pencarian lewat `@produk.comments` otomatis membatasi ke produk yang sama; `to_i` tidak diperlukan karena `find_by(id: "abc")` mengembalikan `nil`. Tambahkan di atas `rate_limit to: 10, within: 1.minute, only: :create, with: -> { redirect_to product_path(params[:product_id], anchor: "diskusi"), alert: "Terlalu banyak komentar. Coba lagi sebentar." }`.
- [ ] **Step 5: Jalankan** `bin/rails test test/controllers/comments_controller_test.rb` → hijau. Catatan: rate limit tidak dites otomatis karena `cache_store` di test adalah `:null_store`; polanya sama dengan `SessionsController`.
- [ ] **Step 6: Commit.** `git add -A && git commit -m "feat: pembeli dapat menulis komentar dan balasan"`

---

### Task 3: Bagian diskusi di halaman produk

**Konsep:** *Partial* (potongan view yang bisa dipakai ulang), *eager loading* (`includes`, supaya tidak N+1), dan keamanan tampilan (*escape*). Tombol "Balas" memakai elemen HTML `<details>` agar tanpa JavaScript.

**Files:**
- Modify: `app/controllers/products_controller.rb`, `app/views/products/show.html.erb`
- Create: `app/views/comments/_section.html.erb`, `_comment.html.erb`, `_form.html.erb`
- Test: `test/controllers/product_discussions_test.rb`

**Interfaces:**
- Consumes: `Comment.utama`, `Comment#replies`, `product_comments_path` (Task 1–2).
- Produces: di `ProductsController#show`: `@comments` (komentar utama, lama ke baru, `includes(:user, replies: :user)`) dan `@jumlah_diskusi` (jumlah komentar berstatus `tampil`, utama + balasan). `render "comments/section", product:, comments:, jumlah:`; wadah dengan `id="diskusi"`.

- [ ] **Step 1: Tulis tes yang gagal** (`ActionDispatch::IntegrationTest`, `get product_url(@produk)`):
  - `"menampilkan komentar dan balasannya"`, judul memuat `Diskusi (2)`
  - `"komentar disembunyikan tidak menampilkan isinya tapi balasannya tetap terlihat"` → `assert_not_includes response.body, "isi rahasia"`, `assert_includes response.body, "disembunyikan oleh admin"`, balasan masih ada
  - `"jumlah diskusi hanya menghitung yang tampil"`
  - `"isi ber-HTML di-escape"` → body `<script>alert(1)</script>`; `assert_includes response.body, "&lt;script&gt;"`; `assert_not_includes response.body, "<script>alert(1)"`
  - `"tamu melihat ajakan masuk dan tidak ada form"` → `assert_select "form[action=?]", product_comments_path(@produk), 0`
  - `"pembeli login melihat form"` → `assert_select "form[action=?]", product_comments_path(@produk)`
- [ ] **Step 2: Jalankan, pastikan gagal.**
- [ ] **Step 3: Siapkan data di `ProductsController#show`** (`@comments`, `@jumlah_diskusi` seperti di Interfaces).
- [ ] **Step 4: Tulis tiga partial.**
  - `_section`: `<section id="diskusi">` berisi judul "Diskusi (N)", form komentar utama bila `current_user`, jika tidak tautan "Masuk untuk ikut berdiskusi" ke `new_session_path`, lalu `render partial: "comments/comment", collection: comments`; pesan "Belum ada diskusi." bila kosong.
  - `_comment`: nama penulis dan waktu; bila `disembunyikan?` tampilkan teks redup "(komentar disembunyikan oleh admin)", selain itu `simple_format(h(comment.body))` — **jangan** `raw`/`html_safe`. Di bawahnya `<details><summary>Balas</summary>` berisi form (hanya bila login) dengan `hidden_field :parent_id`, dan `comment.replies` dirender dengan partial yang sama tetapi tanpa kotak Balas (balasan tidak punya balasan).
  - `_form`: `form_with model: Comment.new, url: product_comments_path(product)` dengan `text_area :body` (`maxlength: Comment::MAX_BODY`), tombol "Kirim", dan `parent_id` opsional lewat local.
  Pakai kelas Bootstrap/`theme.css` yang sudah ada (`eyebrow`, `pill-tag`, `btn btn-ink`, `text-body-secondary`); tidak perlu CSS baru.
- [ ] **Step 5: Pasang di `products/show.html.erb`**, di bawah `</section>` yang ada: `<%= render "comments/section", product: @product, comments: @comments, jumlah: @jumlah_diskusi %>`.
- [ ] **Step 6: Jalankan** `bin/rails test test/controllers/product_discussions_test.rb` → hijau.
- [ ] **Step 7: Lihat di browser** (`bin/dev` atau `bin/rails s`): buka satu produk, tulis komentar dan balasan, coba tulis `<b>tebal</b>` dan pastikan tampil sebagai teks.
- [ ] **Step 8: Commit.** `git add -A && git commit -m "feat: bagian diskusi di halaman produk"`

---

### Task 4: Moderasi di panel admin

**Konsep:** *Namespace admin* yang mewarisi `Admin::BaseController` (otomatis `require_admin`), *member route* (`hide`/`restore`, seperti `ship`/`complete`), dan bang-method dari enum (`comment.disembunyikan!`).

**Files:**
- Modify: `config/routes.rb`, `app/views/admin/shared/_sidebar.html.erb`
- Create: `app/controllers/admin/comments_controller.rb`, `app/views/admin/comments/index.html.erb`
- Test: `test/controllers/admin/comments_controller_test.rb`

**Interfaces:**
- Consumes: `Comment` (status, `tampil!`, `disembunyikan!`), `Admin::BaseController`.
- Produces: `admin_comments_path` (GET, filter `?status=tampil|disembunyikan`, `?page=`), `hide_admin_comment_path(comment)` dan `restore_admin_comment_path(comment)` (PATCH, redirect kembali dengan `status: :see_other`).

- [ ] **Step 1: Tulis tes yang gagal** (buat admin dengan `role: :admin`, pelanggan biasa, produk, beberapa komentar):
  - `"tamu diarahkan ke login"` → `assert_redirected_to new_session_url`
  - `"pelanggan biasa ditolak dari index"` → `assert_redirected_to root_url`
  - `"admin melihat daftar termasuk isi komentar yang disembunyikan"`
  - `"filter status hanya menampilkan yang cocok"`
  - `"admin menyembunyikan lalu menampilkan kembali"` → `assert comment.reload.disembunyikan?`, lalu `assert comment.reload.tampil?`
  - `"pelanggan biasa tidak bisa hide/restore dan status tidak berubah"` dan `"tamu tidak bisa hide"`
  - `"hide komentar yang tidak ada → 404"` → `assert_response :not_found`
- [ ] **Step 2: Jalankan, pastikan gagal.**
- [ ] **Step 3: Rute.** Di `namespace :admin`, tambahkan `resources :comments, only: :index` dengan blok `member` berisi `patch :hide` dan `patch :restore`.
- [ ] **Step 4: Controller** `Admin::CommentsController < Admin::BaseController`: `index` memuat `Comment.includes(:user, :product)` urut terbaru, memfilter bila `params[:status]` termasuk `Comment.statuses.keys` (nilai lain diabaikan), lalu `.page(params[:page]).per(20)`; `hide` dan `restore` memakai `Comment.find(params[:id])` + `disembunyikan!`/`tampil!` + `redirect_back fallback_location: admin_comments_path, notice: ..., status: :see_other`.
- [ ] **Step 5: View `index`.** Mengikuti [admin/customers/index.html.erb](../../../app/views/admin/customers/index.html.erb): header "Diskusi" dengan `eyebrow` jumlah, filter status (select), tabel (waktu, produk dengan tautan ke `product_path`, penulis, isi dipotong dengan `truncate(120)`, "Utama"/"Balasan", badge status, tombol `button_to` Sembunyikan atau Tampilkan), `paginate`, dan pesan kosong. Isi tetap di-escape (default ERB).
- [ ] **Step 6: Menu sidebar.** Di `_sidebar.html.erb`, sebelum "Lihat toko": `admin_nav_link "Diskusi", "chat-dots", admin_comments_path, aktif: controller_path == "admin/comments"`.
- [ ] **Step 7: Jalankan** `bin/rails test test/controllers/admin/comments_controller_test.rb` → hijau.
- [ ] **Step 8: Commit.** `git add -A && git commit -m "feat: moderasi diskusi di panel admin"`

---

### Task 5: Pemeriksaan akhir

- [ ] **Step 1: Semua tes fitur.** `bin/rails test test/models/comment_test.rb test/controllers/comments_controller_test.rb test/controllers/product_discussions_test.rb test/controllers/admin/comments_controller_test.rb` → semua hijau.
- [ ] **Step 2: Seluruh suite.** `bin/rails test`. Jumlah gagal+error tidak boleh lebih besar dari angka yang kamu catat di Task 0.
- [ ] **Step 3: Gaya dan keamanan.** `bin/rubocop app test config` dan `bin/brakeman -q` tanpa temuan baru.
- [ ] **Step 4: Uji manual (jadikan satu akun admin lewat `bin/rails console`: `User.find_by(email_address: "...").admin!`).** Alur: tamu membaca diskusi dan tidak melihat form → login sebagai pembeli, menulis dan membalas → login sebagai admin, buka Admin › Diskusi, sembunyikan satu komentar → cek halaman produk (placeholder muncul, balasan tetap ada) → tampilkan kembali.
- [ ] **Step 5: Siap digabung.** Pakai skill `superpowers:finishing-a-development-branch` bila mau merge atau membuat PR.
