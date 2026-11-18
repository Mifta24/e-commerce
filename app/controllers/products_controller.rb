class ProductsController < ApplicationController
  # Mengambil produk berdasarkan ID di URL sebelum action-action ini dijalankan
  before_action :set_product, only: %i[ show edit update destroy ]
  allow_unauthenticated_access only: %i[index show]   # publik boleh lihat
  before_action :require_admin, except: %i[index show] # sisanya admin saja

  def index
    # Filter opsional lewat ?category=ID. ID yang tidak dikenal dianggap "Semua".
    @categories = Category.order(:name)
    @selected_category = @categories.find_by(id: params[:category])
    @products = Product.order(created_at: :desc)
    @products = @products.where(category: @selected_category) if @selected_category
  end

  def show
  end

  def new
    @product = Product.new
  end

  def create
    @product = Product.new(product_params)
    if @product.save
      redirect_to @product, notice: "Produk berhasil dibuat."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @product.update(product_params)
      redirect_to @product, notice: "Produk berhasil diperbarui."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @product.destroy
    redirect_to products_url, notice: "Produk berhasil dihapus.", status: :see_other
  end

  # untuk mengamankan parameter yang diterima dari form, sehingga hanya parameter yang diizinkan yang dapat digunakan untuk membuat atau memperbarui produk.
  private
    # Use callbacks to share common setup or constraints between actions.
    def set_product
      @product = Product.find(params.expect(:id))
    end
    # 
    def product_params
      params.require(:product).permit(:name, :description, :price, :stock, :category_id)
    end
end
