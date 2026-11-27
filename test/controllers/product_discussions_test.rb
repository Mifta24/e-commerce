require "test_helper"

class ProductDiscussionsTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(name: "Budi", email_address: "budi@example.com", password: "password")
    @penjawab = User.create!(name: "Sari", email_address: "sari@example.com", password: "password")
    @produk = Product.create!(name: "Sneakers", price: 80_000, stock: 3)
  end

  def tulis(body, user: @user, parent: nil, status: :tampil)
    Comment.create!(user: user, product: @produk, body: body, parent: parent, status: status)
  end

  test "menampilkan komentar dan balasannya" do
    utama = tulis("Ukurannya pas?")
    tulis("Pas kok, sudah beli", user: @penjawab, parent: utama)
    get product_url(@produk)
    assert_response :success
    assert_select "#diskusi", /Diskusi \(2\)/
    assert_select "#diskusi", /Ukurannya pas\?/
    assert_select "#diskusi", /Pas kok, sudah beli/
  end

  test "komentar disembunyikan tidak menampilkan isinya tapi balasannya tetap terlihat" do
    utama = tulis("isi rahasia", status: :disembunyikan)
    tulis("balasan masih ada", user: @penjawab, parent: utama)
    get product_url(@produk)
    assert_not_includes response.body, "isi rahasia"
    assert_includes response.body, "disembunyikan oleh admin"
    assert_includes response.body, "balasan masih ada"
  end

  test "jumlah diskusi hanya menghitung yang tampil" do
    tulis("terlihat")
    tulis("tersembunyi", status: :disembunyikan)
    get product_url(@produk)
    assert_select "#diskusi", /Diskusi \(1\)/
  end

  test "isi ber-HTML di-escape" do
    tulis("<script>alert(1)</script>")
    get product_url(@produk)
    assert_includes response.body, "&lt;script&gt;"
    assert_not_includes response.body, "<script>alert(1)"
  end

  test "tamu melihat ajakan masuk dan tidak ada form" do
    get product_url(@produk)
    assert_select "form[action=?]", product_comments_path(@produk), 0
    assert_select "#diskusi a[href=?]", new_session_path
  end

  test "pembeli login melihat form" do
    sign_in_as @user
    get product_url(@produk)
    assert_select "form[action=?]", product_comments_path(@produk)
  end

  test "balasan juga punya tombol balas dan form-nya menyapa penulisnya" do
    utama = tulis("Ukurannya pas?")
    tulis("Pas kok", user: @penjawab, parent: utama)
    sign_in_as @user
    get product_url(@produk)
    assert_select "#diskusi details", 3                # satu di komentar utama, satu di balasan
    assert_select "#diskusi details textarea", text: /@Sari/
  end

  test "komentar utama dibatasi per halaman dan terbaru dulu" do
  7.times { |i| tulis("komentar ke-#{i + 1}") }
  get product_url(@produk)
  assert_includes response.body, "komentar ke-7"
  assert_not_includes response.body, "komentar ke-2"
  assert_select "#diskusi a[href*=?]", "reply_page=2"
  assert_select "#diskusi a[href*=?]", "#diskusi"
end

test "halaman kedua menampilkan komentar yang lebih lama" do
  7.times { |i| tulis("komentar ke-#{i + 1}") }
  get product_url(@produk, reply_page: 2)
  assert_includes response.body, "komentar ke-1"
  assert_includes response.body, "komentar ke-2"
  assert_not_includes response.body, "komentar ke-7"
end

test "balasan dilipat dan menampilkan jumlahnya" do
  utama = tulis("Tanya")
  tulis("Jawab 1", user: @penjawab, parent: utama)
  tulis("Jawab 2", user: @penjawab, parent: utama)
  get product_url(@produk)
  assert_select "#diskusi details > summary", /Lihat 2 balasan/
  assert_select "#diskusi details[open]", 0
end

test "balasan terbuka kalau ada ?buka=id komentar utamanya" do
  utama = tulis("Tanya")
  tulis("Jawab", user: @penjawab, parent: utama)
  get product_url(@produk, buka: utama.id)
  assert_select "#diskusi details[open] > summary", /Lihat 1 balasan/
end
end
