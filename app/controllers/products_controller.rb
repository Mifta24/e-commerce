# Katalog toko untuk pembeli: hanya melihat. Mengelola produk ada di Admin::ProductsController.
class ProductsController < ApplicationController
  allow_unauthenticated_access # katalog terbuka untuk umum

  def index
    @categories = Category.order(:name)
    @selected_category = @categories.find_by(id: params[:category])
    # Filter opsional lewat ?category=ID. ID yang tidak dikenal dianggap "Semua".
    @products = Product.search(params[:q]).order(created_at: :desc, id: :desc)
    @products = @products.where(category: @selected_category) if @selected_category
    @products = @products.page(params[:page]).per(12)
  end

  def show
    @product = Product.find(params.expect(:id))
    # komentar utama saja; balasan ikut dimuat sekaligus lewat includes (menghindari N+1)
    @comments = @product.comments.utama.includes(:user, replies: :user).order(:created_at, :id)
    # jumlah diskusi hanya menghitung yang tampil (utama + balasan)
    @jumlah_diskusi = @product.comments.tampil.count
  end
end
