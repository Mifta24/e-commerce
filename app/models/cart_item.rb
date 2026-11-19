class CartItem < ApplicationRecord
  belongs_to :cart
  belongs_to :product

  validates :quantity,  numericality: { only_integer: true, greater_than: 0 }
  validate :quantity_within_stock

  def subtotal
    quantity * product.price
  end
  
  private
  def quantity_within_stock
    # kembalikan jika product atau quantity nil, karena validasi ini hanya relevan jika keduanya ada
   return unless product && quantity  
   errors.add(:quantity, "exceeds available stock") if quantity > product.stock
  end
end
