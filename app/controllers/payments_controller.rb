class PaymentsController < ApplicationController
  def create
    order = current_user.orders.find(params[:order_id])

    if !order.awaiting_payment?
      redirect_to order_path(order), alert: "Pesanan ini tidak sedang menunggu pembayaran."
    else
      payment = order.payments.new(payment_params)
      payment.amount = order.total

      if payment.save
        redirect_to order_path(order), notice: "Bukti pembayaran terkirim. Mohon tunggu verifikasi admin."
      else
        redirect_to order_path(order), alert: payment.errors.full_messages.to_sentence
      end
    end
  rescue ActiveRecord::RecordNotUnique
    # tombol kirim ditekan dua kali, atau dua tab sekaligus
    redirect_to order_path(order), alert: "Bukti pembayaran sudah dikirim."
  end

  private

  def payment_params
    params.expect(payment: [ :sender_name, :sender_bank, :proof ])
  end
end
