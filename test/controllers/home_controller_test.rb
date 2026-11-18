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

  test "renders brand strip and testimonials" do
    get root_url
    assert_select ".brand-strip .brand-item", 5
    assert_select ".testimonial", 3
  end

  test "top product section is shown only when products exist" do
    Product.destroy_all
    get root_url
    assert_select ".top-product", 0

    Product.create!(name: "Tas Biru", description: "Tas ramah lingkungan", price: 5000, stock: 1)
    get root_url
    assert_select ".top-product", 1
    assert_select ".top-product", /Tas Biru/
  end

  test "favorite picks can be filtered by category" do
    Product.destroy_all
    sepatu = Category.create!(name: "Sepatu")
    baju = Category.create!(name: "Baju")
    Product.create!(name: "Sneakers", price: 1000, stock: 1, category: sepatu)
    Product.create!(name: "Kemeja", price: 1000, stock: 1, category: baju)

    get root_url
    assert_select ".pick", 2

    get root_url(category: sepatu.id)
    assert_select ".pick", 1
    assert_select ".pick-name", "Sneakers"
    assert_select ".filter-pill.active", "Sepatu"
  end

  test "unknown category filter falls back to all products" do
    Product.destroy_all
    Product.create!(name: "Sneakers", price: 1000, stock: 1)

    get root_url(category: 999_999)
    assert_select ".pick", 1
    assert_select ".filter-pill.active", "Semua"
  end
end
