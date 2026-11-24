class HomeController < ApplicationController
  # supaya bisa diakses tanpa login, tambahkan allow_unauthenticated_access
  allow_unauthenticated_access only: %i[index]
  def index
    @featured_products = Product.includes(:category).with_attached_image.order(created_at: :desc).limit(3)
    # favorites diapkai untuk menampilkan produk favorit berdasarkan jumlah favorit terbanyak, dengan menggunakan counter_cache yang telah ditambahkan pada model Favorite. Dengan menggunakan counter_cache, kita dapat mengurutkan produk berdasarkan jumlah favorit tanpa perlu melakukan query tambahan ke tabel favorites.
    favorites = Product.includes(:category).with_attached_image.order(favorites_count: :desc, created_at: :desc)
    @top_product = Product.top_of_the_month

    # Favorite Picks: bisa difilter dengan ?category=ID. ID yang tidak dikenal dianggap "Semua".
    @categories = Category.order(:name)
    @selected_category = @categories.find_by(id: params[:category])
    favorites = Product.includes(:category).order(created_at: :desc)
    favorites = favorites.where(category: @selected_category) if @selected_category
    @favorite_products = favorites.limit(8)
  end
end
