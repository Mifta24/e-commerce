require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "should get index at root" do
    get root_url
    assert_response :success
    assert_select "nav.site-nav"
    assert_select "h1.hero-title"
  end

  test "shows up to 3 featured products as cards" do
    4.times { |i| Product.create!(name: "Produk #{i}", price: 1000 * (i + 1), stock: 1) }

    get root_url
    assert_select ".hero-card", 3
  end

  test "shows empty state when there are no products" do
    Product.destroy_all

    get root_url
    assert_select ".hero-card", 0
    assert_select "a", "Tambah Produk"
  end
end
