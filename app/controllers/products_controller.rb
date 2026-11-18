class ProductsController < ApplicationController
  # Mengambil produk berdasarkan ID di URL sebelum action-action ini dijalankan
  before_action :set_product, only: %i[ show edit update destroy ]

  def index
    @products = Product.order(created_at: :desc)
  end

  def show
  end

  def new
    @product = Product.new
  end

  def create
    @product = Product.new(product_params)
    if @product.save
      redirect_to @product, notice: "Product was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @product.update(product_params)
      redirect_to @product, notice: "Product was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @product.destroy
    redirect_to products_url, notice: "Product was successfully destroyed.", status: :see_other
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
