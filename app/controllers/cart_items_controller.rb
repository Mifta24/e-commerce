class CartItemsController < ApplicationController
  allow_unauthenticated_access
  before_action :set_item, only: %i[update destroy]

  def create
    product  = Product.find(params.expect(:product_id))
    quantity = [params.fetch(:quantity, 1).to_i, 1].max
    item     = current_cart!.add_product(product, quantity)

    if item.errors.any?
      redirect_back fallback_location: cart_path, alert: item.errors.full_messages.to_sentence
    else
      redirect_back fallback_location: cart_path, notice: "#{product.name} ditambahkan ke keranjang."
    end
  end

  def update
    if @item.update(quantity: params.expect(cart_item: [:quantity])[:quantity])
      redirect_to cart_path
    else
      redirect_to cart_path, alert: @item.errors.full_messages.to_sentence
    end
  end

  def destroy
    @item.destroy
    redirect_to cart_path, status: :see_other
  end

  private

  def set_item
    @item = current_cart!.cart_items.find(params[:id])
  end
end
