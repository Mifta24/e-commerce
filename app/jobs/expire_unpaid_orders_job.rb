class ExpireUnpaidOrdersJob < ApplicationJob
  queue_as :default

  def perform
    Order.expired_unpaid.find_each do |order|
      order.cancel_if_expired
     rescue => e
      # satu pesannan gagal dibatalkan tidak menghentikan job, tapi dicatat di log
      Rails.logger.error("Gagal membatalkan pesanan #{order.id}: #{e.message}")
    end
  end
end
