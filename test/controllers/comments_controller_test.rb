require "test_helper"

class CommentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(name: "Budi", email_address: "budi@example.com", password: "password")
    @produk = Product.create!(name: "Sneakers", price: 80_000, stock: 3)
    @produk_lain = Product.create!(name: "Kemeja", price: 50_000, stock: 3)
  end

  # mengirim komentar ke @produk, seperti form di halaman produk
  def kirim(body: "Ukurannya pas?", parent_id: nil)
    # mengirim permintaan POST ke URL komentar produk
    post product_comments_url(@produk), params: { comment: { body: body, parent_id: parent_id } }
  end

  test "tamu diarahkan ke login dan tidak membuat komentar" do
    # assert_no_difference untuk memastikan tidak ada perubahan jumlah komentar di database saat kirim dipanggil
    assert_no_difference "Comment.count" do
      kirim
    end
    assert_redirected_to new_session_url
  end

  test "pembeli login membuat komentar utama" do
    sign_in_as @user
    assert_difference "Comment.count", 1 do
      kirim
    end
    assert_redirected_to product_url(@produk, anchor: "diskusi")
    assert_equal @user, Comment.last.user
  end

  test "body kosong tidak membuat komentar dan memberi pesan" do
    sign_in_as @user
    assert_no_difference "Comment.count" do
      kirim(body: "   ")
    end
    assert_redirected_to product_url(@produk, anchor: "diskusi")
    assert_not_nil flash[:alert]
  end

  test "balasan ke balasan masuk ke komentar utama" do
    sign_in_as @user
    utama = Comment.create!(user: @user, product: @produk, body: "Tanya")
    balasan = Comment.create!(user: @user, product: @produk, body: "Jawab", parent: utama)
    assert_difference "Comment.count", 1 do
      kirim(body: "Terima kasih", parent_id: balasan.id)
    end
    # memastikan komentar baru yang dibuat memiliki parent_id yang sama dengan komentar utama, bukan balasan
    assert_equal utama, Comment.order(:id).last.parent
  end

  test "parent_id yang tidak valid ditolak" do
    sign_in_as @user
    lain = Comment.create!(user: @user, product: @produk_lain, body: "Tanya")
    # id komentar produk lain, id yang tidak ada, dan teks bukan angka
    [ lain.id, 0, "abc" ].each do |id|
      assert_no_difference "Comment.count" do
        kirim(parent_id: id)
      end
      assert_not_nil flash[:alert]
    end
  end
end
