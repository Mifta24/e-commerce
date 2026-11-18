require "test_helper"

class ProductsControllerTest < ActionDispatch::IntegrationTest
  setup do
    Product.destroy_all
    @sepatu = Category.create!(name: "Sepatu")
    @baju = Category.create!(name: "Baju")
    @sneakers = Product.create!(name: "Sneakers", description: "Nyaman dipakai", price: 80_000, stock: 3, category: @sepatu)
    @kemeja = Product.create!(name: "Kemeja", price: 50_000, stock: 0, category: @baju)
  end

  test "index shows a card per product with formatted price" do
    get products_url
    assert_response :success
    assert_select ".pick", 2
    assert_select ".pick-price", /Rp80\.000/
  end

  test "index marks out-of-stock products" do
    get products_url
    assert_select ".pill-tag--danger", "Habis"
  end

  test "index can be filtered by category" do
    get products_url(category: @sepatu.id)
    assert_select ".pick", 1
    assert_select ".pick-name", "Sneakers"
    assert_select ".filter-pill.active", "Sepatu"
  end

  test "index falls back to all products for an unknown category" do
    get products_url(category: 999_999)
    assert_select ".pick", 2
    assert_select ".filter-pill.active", "Semua"
  end

  test "show displays product details" do
    get product_url(@sneakers)
    assert_response :success
    assert_select "h1", /Sneakers/
    assert_select ".detail-price", "Rp80.000"
    assert_select "a[href=?]", category_path(@sepatu)
  end

  test "new and edit render the form" do
    get new_product_url
    assert_response :success
    assert_select "form.form-card"

    get edit_product_url(@sneakers)
    assert_response :success
    assert_select "form.form-card input[name='product[name]'][value=Sneakers]"
  end

  test "create with valid params redirects to the product" do
    assert_difference("Product.count") do
      post products_url, params: { product: { name: "Topi", price: 1000, stock: 1 } }
    end
    assert_redirected_to product_url(Product.find_by!(name: "Topi"))
    follow_redirect!
    assert_select ".flash", "Produk berhasil dibuat."
  end

  test "create with invalid params re-renders the form with errors" do
    assert_no_difference("Product.count") do
      post products_url, params: { product: { name: "", price: 1000, stock: 1 } }
    end
    assert_response :unprocessable_entity
    assert_select ".alert-danger", /Gagal menyimpan/
  end

  test "update and destroy" do
    patch product_url(@sneakers), params: { product: { name: "Sneakers Baru" } }
    assert_redirected_to product_url(@sneakers)
    assert_equal "Sneakers Baru", @sneakers.reload.name

    assert_difference("Product.count", -1) { delete product_url(@sneakers) }
    assert_redirected_to products_url
  end
end
