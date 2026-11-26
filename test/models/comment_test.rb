require "test_helper"

class CommentTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(name: "Budi DOng", email_address: "budi@example.com", password: "password")
   @produk = Product.create!(name: "Produk A", description: "Deskripsi Produk A", price: 10_000, stock: 3)
@produk2 = Product.create!(name: "Produk B", description: "Deskripsi Produk B", price: 20_000, stock: 3)
  end

  # membuat comment baru; atribut bisa ditimpapertes
  def newComment(**atribut)
    Comment.new({
      user: @user,
      product: @produk,
      body: " pas ga???",
      status: 0
    }.merge(atribut))
  end

  test "valid dengan atribnut lengkap" do
    assert newComment.valid?
  end

 test "body wajib diisi termasuk cuma spasi" do
  komentar = newComment(body: "   ")
  assert_not komentar.valid?
  assert_includes komentar.errors[:body], "can't be blank"
end

test "body max 1000 karakter" do
  komentar = newComment(body: "a" * 1001)
  assert_not komentar.valid?
  assert_includes komentar.errors[:body], "is too long (maximum is 1000 characters)"
end

  test "status awal tampil" do
    assert newComment.tampil?
  end

  test "balasan harus satu produk dengan induknya" do
    utama = newComment.tap(&:save!) #buat, simpan lalu kembalikan objeknya
    balasan = newComment(product: @produk2, parent: utama)
    # assert not untuk memastikan balasan tidak valid karena produk berbeda dengan induknya
    assert_not balasan.valid?
    # assert balasan.errors[:parent].any untuk memastikan ada error pada kolom parent karena produk berbeda dengan induknya
    assert balasan.errors[:parent].any?
  end

  test "balasan ke balasan ditolak" do
    utama = newComment.tap(&:save!)
    balasan = newComment(parent: utama).tap(&:save!)
    # assert_not untuk memastikan balasan ke balasan tidak valid
    assert_not newComment(parent: balasan).valid?
  end

  test "scope utama hanya komentar tanpa induk" do
    utama = newComment.tap(&:save!)
    newComment(parent: utama).save!
    # assert_equal untuk memastikan hanya komentar utama yang dikembalikan oleh scope utama
   assert_equal [utama], Comment.utama.to_a
  end

   test "menghapus induk menghapus balasannya" do
    utama = newComment.tap(&:save!)
    newComment(parent: utama).save!
    assert_difference "Comment.count", -2 do
      utama.destroy
    end
  end

  test "menghapus produk menghapus komentarnya" do
    newComment.save!
    assert_difference "Comment.count", -1 do
      @produk.destroy
    end
  end

end
