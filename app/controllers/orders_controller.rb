class OrdersController < ApplicationController
  before_action :require_filled_cart, only: %i[new create]

  def index
    @orders = current_user.orders.includes(:payments).order(created_at: :desc)

  end

  def show
    @order = current_user.orders.find(params[:id])
  end

  def new
    @cart = current_cart
    @addresses = current_user.addresses
  end

  def create
    address = current_user.addresses.find_by(id: params[:address_id])

    if address.nil?
      redirect_to new_order_path, alert: "Pilih alamat pengiriman dulu."
    else
      order = Order.checkout(user: current_user, cart: current_cart, address: address)

      # Jika pesanan berhasil dibuat, arahkan pengguna ke halaman detail pesanan. Jika gagal, arahkan kembali ke keranjang dengan pesan kesalahan.
      if order.persisted?
        redirect_to order_path(order), notice: "Pesanan berhasil dibuat."
      else
        redirect_to cart_path, alert: order.errors.full_messages.to_sentence
      end
    end
  end

  # Pelanggan hanya boleh membatalkan pesanan yang belum dibayar dan belum
  # punya bukti bayar yang menunggu verifikasi.
  def cancel
    order = current_user.orders.find(params[:id])

    if order.awaiting_payment? && order.cancel
      redirect_to order_path(order), notice: "Pesanan dibatalkan."
    else
      redirect_to order_path(order), alert: "Pesanan ini tidak bisa dibatalkan."
    end
  end

  private

  def require_filled_cart
    if current_cart.nil? || current_cart.cart_items.empty?
      redirect_to cart_path, alert: "Keranjang kamu masih kosong."
    end
  end
end
