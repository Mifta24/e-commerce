class HomeController < ApplicationController
  def index
    @featured_products = Product.includes(:category).order(created_at: :desc).limit(3)
  end
end
