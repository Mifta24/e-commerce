class Admin::OrdersController < Admin::BaseController
  before_action :set_order, only: %i[show ship complete cancel]

  def index
    @status = params[:status]
    @orders = Order.includes(:user, :payments).order(created_at: :desc, id: :desc)
    # filter hanya dipakai kalau berisi status yang dikenal
    @orders = @orders.where(status: @status) if Order.statuses.key?(@status)
    @orders = @orders.page(params[:page]).per(20)
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

  def set_order
    @order = Order.find(params[:id])
  end
end
