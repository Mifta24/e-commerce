module OrdersHelper
  # Teks dan warna badge untuk tiap status
  ORDER_STATUS = {
    "pending"   => { label: "Menunggu pembayaran", color: "warning" },
    "paid"      => { label: "Dibayar",             color: "info" },
    "shipped"   => { label: "Dikirim",             color: "primary" },
    "completed" => { label: "Selesai",             color: "success" },
    "canceled"  => { label: "Dibatalkan",          color: "secondary" }
  }.freeze

  PAYMENT_STATUS = {
    "submitted" => { label: "Menunggu verifikasi", color: "warning" },
    "confirmed" => { label: "Dikonfirmasi",        color: "success" },
    "rejected"  => { label: "Ditolak",             color: "danger" }
  }.freeze

  def order_status_label(status)
    ORDER_STATUS.fetch(status.to_s)[:label]
  end

  def order_status_badge(order)
    style = ORDER_STATUS.fetch(order.status)
    tag.span(style[:label], class: "badge text-bg-#{style[:color]}")
  end

  def payment_status_badge(payment)
    style = PAYMENT_STATUS.fetch(payment.status)
    tag.span(style[:label], class: "badge text-bg-#{style[:color]}")
  end
end
