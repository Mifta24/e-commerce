class Admin::DashboardController < Admin::BaseController
  def show
    # penjualan 30 hari terakhir (pesanan yang sudah dibayar)
    penjualan = Order.laku.dalam_hari(30)
    @pendapatan = penjualan.sum(:total)
    @jumlah_pesanan = penjualan.count

    # pekerjaan yang menunggu admin
    @perlu_verifikasi = Payment.submitted.count
    @perlu_dikirim = Order.paid.count

    # produk terlaris: jumlah terjual dihitung dari quantity, disimpan sebagai kolom bayangan "terjual"
    @terlaris = Product
      .joins(order_items: :order)
      .merge(penjualan)
      .group("products.id")
      .select("products.*, SUM(order_items.quantity) AS terjual")
      .order("terjual DESC")
      .limit(5)

    @stok_menipis = Product.menipis.order(:stock, :name).limit(10)
    @stok_habis = Product.habis.count

    @pesanan_terbaru = Order.includes(:user).order(created_at: :desc, id: :desc).limit(5)
  end
end
 