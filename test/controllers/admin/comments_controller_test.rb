require "test_helper"

class Admin::CommentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.create!(name: "Admin", email_address: "admin@example.com", password: "password", role: :admin)
    @pelanggan = User.create!(name: "Budi", email_address: "budi@example.com", password: "password")
    @produk = Product.create!(name: "Sneakers", price: 80_000, stock: 3)
    @tampil = Comment.create!(user: @pelanggan, product: @produk, body: "komentar terlihat")
    @tersembunyi = Comment.create!(user: @pelanggan, product: @produk, body: "komentar kasar", status: :disembunyikan)
  end

  test "tamu diarahkan ke login" do
    get admin_comments_url
    assert_redirected_to new_session_url
  end

  test "pelanggan biasa ditolak dari index" do
    sign_in_as @pelanggan
    get admin_comments_url
    assert_redirected_to root_url
  end

  test "admin melihat daftar termasuk isi komentar yang disembunyikan" do
    sign_in_as @admin
    get admin_comments_url
    assert_response :success
    assert_includes response.body, "komentar terlihat"
    assert_includes response.body, "komentar kasar"
  end

  test "filter status hanya menampilkan yang cocok" do
    sign_in_as @admin
    get admin_comments_url(status: "disembunyikan")
    assert_includes response.body, "komentar kasar"
    assert_not_includes response.body, "komentar terlihat"
  end

  test "admin menyembunyikan lalu menampilkan kembali" do
    sign_in_as @admin
    patch hide_admin_comment_url(@tampil)
    assert @tampil.reload.disembunyikan?
    patch restore_admin_comment_url(@tampil)
    assert @tampil.reload.tampil?
  end

  test "pelanggan biasa tidak bisa hide atau restore" do
    sign_in_as @pelanggan
    patch hide_admin_comment_url(@tampil)
    assert @tampil.reload.tampil?
    patch restore_admin_comment_url(@tersembunyi)
    assert @tersembunyi.reload.disembunyikan?
  end

  test "tamu tidak bisa hide" do
    patch hide_admin_comment_url(@tampil)
    assert_redirected_to new_session_url
    assert @tampil.reload.tampil?
  end

  test "hide komentar yang tidak ada memberi 404" do
    sign_in_as @admin
    patch hide_admin_comment_url(id: 0)
    assert_response :not_found
  end
end
