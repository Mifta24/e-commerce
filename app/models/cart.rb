class Cart < ApplicationRecord
  belongs_to :user, optional: true
  has_many :cart_items, dependent: :destroy
  has_many :products, through: :cart_items
  has_secure_token :token

  # tambah product ke cart, jika product sudah ada di cart, maka quantity akan ditambah
  def add_product(product, quantity = 1)
    item = cart_items.find_or_initialize_by(product: product)
    item.quantity = item.persisted? ? item.quantity + quantity : quantity
    item.save
    item
    # kalau ada duplicate, akan ada ActiveRecord::RecordNotUnique, maka kita bisa retry
  rescue ActiveRecord::RecordNotUnique
    retry
  end

  # pindahi semua item dari cart lain ke cart ini, lalu hapus cart lain
  def absorb(other_cart)
    other_cart.cart_items.find_each do |item|
      add_product(item.product, item.quantity)
    end
    other_cart.destroy
  end

  def total_items = cart_items.sum(:quantity)

  def total = cart_items.includes(:product).sum(&:subtotal)

end
