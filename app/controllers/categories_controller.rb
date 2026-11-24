# Daftar kategori untuk pembeli: hanya melihat. Mengelola kategori ada di Admin::CategoriesController.
class CategoriesController < ApplicationController
  allow_unauthenticated_access # terbuka untuk umum

  def index
    @categories = Category.includes(:products).order(:name)
  end

  def show
    @category = Category.find(params.expect(:id))
    @products = @category.products.order(created_at: :desc)
  end
end
