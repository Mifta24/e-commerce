class Admin::ProductsController < Admin::BaseController
  before_action :set_product, only: %i[edit update destroy]

  def index
    @categories = Category.order(:name)
    @selected_category = @categories.find_by(id: params[:category])

    @products = Product.search(params[:q])
                       .includes(:category).with_attached_image
                       .order(created_at: :desc, id: :desc)
    @products = @products.where(category: @selected_category) if @selected_category
    @products = @products.menipis if params[:stok] == "menipis"
    @products = @products.habis if params[:stok] == "habis"
    @products = @products.page(params[:page]).per(20)
  end

  def new
    @product = Product.new
  end

  def create
    @product = Product.new(product_params)
    if @product.save
      redirect_to admin_products_path, notice: "Produk berhasil dibuat."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @product.update(product_params)
      redirect_to admin_products_path, notice: "Produk berhasil diperbarui."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @product.destroy
      redirect_to admin_products_path, notice: "Produk berhasil dihapus.", status: :see_other
    else
      # destroy gagal kalau produk pernah dipesan (order_items memakai restrict_with_error)
      redirect_to admin_products_path, status: :see_other,
        alert: "Produk tidak bisa dihapus karena sudah pernah dipesan. Ubah stoknya jadi 0 kalau tidak dijual lagi."
    end
  end

  private

  def set_product
    @product = Product.find(params.expect(:id))
  end

  def product_params
    params.require(:product).permit(:name, :description, :price, :stock, :category_id, :image)
  end
end
