class Order < ApplicationRecord
  belongs_to :user
  has_many :order_items, dependent: :destroy

  enum :status, { pending: 0, paid: 1, shipped: 2, completed: 3, canceled: 4 }

  validates :recipient_name, :phone, :street, :city, :province, :postal_code, presence: true

  def self.checkout(user:, cart:, address:)
   order= user.orders.build(
    recipient_name: address.recipient_name,
    phone: address.phone,
    street: address.street,
    city: address.city,
    province: address.province,
    postal_code: address.postal_code,
   )
   total = 0

   transaction do
    # urutatan tetap supaya ada dua checkout bersamaan gak saling nunggu
    cart.cart_items.includes(:product).order(:product_id).each do |item|
      product = item.product
      product.lock!

      if item.quantity > product.stock
        order.errors.add(:base, "Stok produk #{product.name} tidak cukup")
        raise ActiveRecord::Rollback
      end

      order.order_items.build(
        product: product,
        product_name: product.name,
        quantity: item.quantity,
        unit_price: product.price,
      )

      # transaksi berhasil, kurangi stok produk
      product.update!(stock: product.stock - item.quantity)
      total+= item.quantity * product.price
    end

    order.total = total
    order.save!
    cart.cart_items.destroy_all
  end

    order
  end
end
