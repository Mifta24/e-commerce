require "test_helper"

class RatingTest < ActiveSupport::TestCase
  setup do
    @user   = User.create!(name: "Budi", email_address: "budi@example.com", password: "password")
    @produk = Product.create!(name: "Produk A", price: 10_000, stock: 3)
    buat_pesanan(user: @user, produk: @produk)   # completed
  end

  def buat(**atribut)
    Rating.new({ user: @user, product: @produk, stars: 5 }.merge(atribut))
  end

  test "valid untuk pembeli completed" do
    assert buat.valid?
  end

  test "stars harus bilangan bulat 1 sampai 5" do
  [1, 5].each { |n| assert buat(stars: n).valid?, "#{n} harusnya valid" }
  [0, 6, nil, "4.5", "abc"].each { |n| refute buat(stars: n).valid?, "#{n.inspect} harusnya ditolak" }
end
end