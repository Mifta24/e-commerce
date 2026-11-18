class CartItem < ApplicationRecord
  belongs_to :cart
  belongs_to :product

  validates :quantity,  numericality: { only_integer: true, greater_than: 0 }
  validate :quality_within_stock

  def subtotal
    quantity * product.pretty_inspect 
  end

  private
  def quantity_within_stock
   return unless product && quantity
   errors.add(:quantity, "exceeds available stock") if quantity > product.stock
  end
end
