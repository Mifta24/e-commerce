class Admin::PaymentsController < Admin::BaseController
  before_action :set_payment

  def confirm
    # hanya bukti yang menunggu verifikasi, dan pesanannya masih pending
    if @payment.submitted? && @payment.order.pending?
      @payment.confirm!
      redirect_to admin_order_path(@payment.order), notice: "Pembayaran dikonfirmasi. Pesanan sekarang berstatus paid."
    else
      redirect_to admin_order_path(@payment.order), alert: "Pembayaran ini tidak bisa dikonfirmasi."
    end
  end

  def reject
    alasan = params[:note].to_s.strip

    if alasan.blank?
      redirect_to admin_order_path(@payment.order), alert: "Alasan penolakan wajib diisi."
    elsif @payment.submitted?
      @payment.reject!(alasan)
      redirect_to admin_order_path(@payment.order), notice: "Pembayaran ditolak. Pelanggan bisa mengunggah bukti baru."
    else
      redirect_to admin_order_path(@payment.order), alert: "Pembayaran ini sudah diproses."
    end
  end

  private

  def set_payment
    @payment = Payment.find(params[:id])
  end
end
