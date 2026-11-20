class FavoritesController < ApplicationController
  before_action :set_favorite, only: %i[ show edit update destroy ]

  # GET /favorites or /favorites.json
  def index
    @products = current_user.favorite_products.with_attached_image.order("favorites.created_at DESC")
  end

  # GET /favorites/1 or /favorites/1.json
  def show
  end

  # GET /favorites/new
  def create
    product = Product.find(params[:product_id])
    current_user.favorites.find_or_create_by(product: product)
    redirect_back fallback_location: product_path(product), notice: "Produk berhasil ditambahkan ke favorit."
  end



  # DELETE /favorites/1 or /favorites/1.json
  def destroy
    favorite = current_user.favorites.find(params[:id])

    favorite.destroy
    redirect_back fallback_location: product_path(favorite.product), notice: "Produk berhasil dihapus dari favorit."
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_favorite
      @favorite = Favorite.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def favorite_params
      params.fetch(:favorite, {})
    end
end
