class Admin::OrdersController < Admin::BaseController
  before_action :set_order, only: %i[show ship complete cancel]

    def index
    @status = params[:status].to_s
    @q = params[:q].to_s.strip
    @dari = baca_tanggal(params[:dari])
    @sampai = baca_tanggal(params[:sampai])

    @orders = Order.includes(:user, :payments).order(created_at: :desc, id: :desc)
    @orders = @orders.search(@q).dari_tanggal(@dari).sampai_tanggal(@sampai)
    # filter status hanya dipakai kalau berisi nilai yang dikenal
    if @status == "verifikasi"
      @orders = @orders.menunggu_verifikasi
    elsif Order.statuses.key?(@status)
      @orders = @orders.where(status: @status)
    end
    @orders = @orders.page(params[:page]).per(20)

    # dibawa ke tautan filter status supaya pencarian tidak hilang saat pindah status
    @filter = { q: @q, dari: @dari, sampai: @sampai }.compact_blank
  end


  def show
    @payments = @order.payments.order(:created_at, :id)
  end

  def ship
  if @order.ship(courier: params[:courier], tracking_number: params[:tracking_number])
    redirect_to admin_order_path(@order), notice: "Pesanan ditandai sudah dikirim."
  else
    pesan = @order.errors.full_messages.to_sentence.presence || "Hanya pesanan berstatus paid yang bisa dikirim."
    redirect_to admin_order_path(@order), alert: pesan
   end
  end


  def complete
    if @order.complete
      redirect_to admin_order_path(@order), notice: "Pesanan ditandai selesai."
    else
      redirect_to admin_order_path(@order), alert: "Hanya pesanan yang sudah dikirim yang bisa diselesaikan."
    end
  end

  def cancel
    if @order.cancel
      redirect_to admin_order_path(@order), notice: "Pesanan dibatalkan dan stok dikembalikan."
    else
      redirect_to admin_order_path(@order), alert: "Pesanan ini tidak bisa dibatalkan."
    end
  end

  private

    # "2026-11-25" -> Date; teks kosong atau tidak valid -> nil (filter diabaikan)
  def baca_tanggal(teks)
    Date.iso8601(teks.to_s) if teks.present?
  rescue Date::Error
    nil
  end

  def set_order
    @order = Order.find(params[:id])
  end
end
