class HomeController < ApplicationController
  def index
    @featured_products = Product.includes(:category).order(created_at: :desc).limit(3)
    @top_product = Product.top_of_the_month

    # Favorite Picks: bisa difilter dengan ?category=ID. ID yang tidak dikenal dianggap "Semua".
    @categories = Category.order(:name)
    @selected_category = @categories.find_by(id: params[:category])
    favorites = Product.includes(:category).order(created_at: :desc)
    favorites = favorites.where(category: @selected_category) if @selected_category
    @favorite_products = favorites.limit(8)
  end
end
