class Admin::DashboardController < Admin::BaseController
  # PERIODE digunakan untuk menentukan periode waktu yang akan digunakan dalam perhitungan statistik penjualan, misalnya 7 hari, 30 hari, atau 90 hari.
  PERIODE = [7, 30, 90].freeze
  def show
     # hanya terima 7, 30, atau 90; nilai lain (atau kosong) jadi 30
    @hari = PERIODE.include?(params[:hari].to_i) ? params[:hari].to_i : 30

    # penjualan 30 hari terakhir (pesanan yang sudah dibayar)
    penjualan = Order.laku.dalam_hari(@hari)
    @grafik=Order.penjualan_per_hari(@hari)
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

    @pesanan_terbaru = Order.includes(:user, :payments).order(created_at: :desc, id: :desc).limit(5)
  end
end
 