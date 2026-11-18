class ProductsController < ApplicationController
  def index
    @products = Product.order(created_at: :desc)
  end

  def show
    @product = Product.find(params[:id])
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
    @product = Product.find(params[:id])
  end

  def update
    @product = Product.find(params[:id])
    if @product.update(product_params)
      redirect_to @product, notice: "Product was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @product = Product.find(params[:id])
    @product.destroy
    redirect_to products_url, notice: "Product was successfully destroyed.", status: :see_other
  end

  # untuk mengamankan parameter yang diterima dari form, sehingga hanya parameter yang diizinkan yang dapat digunakan untuk membuat atau memperbarui produk.
  private
    def product_params
      params.require(:product).permit(:name, :description, :price, :stock)
    end
end
