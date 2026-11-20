class Order < ApplicationRecord
  belongs_to :user
  has_many :order_items, dependent: :destroy
  has_many :payments, dependent: :destroy

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

  # pemabayran terbaru bisa nil jika belum ada pembayaran
  def latest_payment
    payments.order(:created_at, :id).last
  end

  # true jika user belum bayar dan belum ada pembayaran yang diterima bisa unggah bukti pembayaran, atau jika user sudah bayar tapi pembayaran ditolak bisa unggah bukti pembayaran lagi
  def awaiting_payment?
   pending? && (  latest_payment.nil? || latest_payment.rejected? )
  end

    # batas waktu pembayaran (hanya informasi; belum ada pembatalan otomatis)
  def payment_deadline
    created_at + Rails.configuration.x.payment.deadline_hours.hours
  end

end
