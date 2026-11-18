require "test_helper"

class CategoriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @category = categories(:one)
  end

  test "should get index" do
    get categories_url
    assert_response :success
  end

  test "should get new" do
    get new_category_url
    assert_response :success
  end

  test "should create category" do
    assert_difference("Category.count") do
      post categories_url, params: { category: { name: "Kategori Baru" } }
    end

    assert_redirected_to category_url(Category.last)
  end

  test "should show category" do
    get category_url(@category)
    assert_response :success
  end

  test "should get edit" do
    get edit_category_url(@category)
    assert_response :success
  end

  test "should update category" do
    patch category_url(@category), params: { category: { name: @category.name } }
    assert_redirected_to category_url(@category)
  end

  test "should destroy category" do
    assert_difference("Category.count", -1) do
      delete category_url(@category)
    end

    assert_redirected_to categories_url
  end

  test "index shows category cards with product counts" do
    Product.destroy_all
    Product.create!(name: "Sneakers", price: 1000, stock: 1, category: @category)

    get categories_url
    assert_select ".category-card", Category.count
    assert_select "#category_#{@category.id} .category-count", "1 produk"
  end

  test "show lists the products of the category" do
    Product.destroy_all
    Product.create!(name: "Sneakers", price: 1000, stock: 1, category: @category)
    Product.create!(name: "Lainnya", price: 1000, stock: 1)

    get category_url(@category)
    assert_select ".pick", 1
    assert_select ".pick-name", "Sneakers"
  end

  test "create with blank name re-renders the form with errors" do
    assert_no_difference("Category.count") do
      post categories_url, params: { category: { name: "" } }
    end
    assert_response :unprocessable_content
    assert_select ".alert-danger"
  end
end
