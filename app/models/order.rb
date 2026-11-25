class Order < ApplicationRecord
  belongs_to :user
  has_many :order_items, dependent: :destroy
  has_many :payments, dependent: :destroy

  enum :status, { pending: 0, paid: 1, shipped: 2, completed: 3, canceled: 4 }
  # konstanta untuk daftar kurir yang tersedia. Konstanta ini digunakan untuk membatasi pilihan kurir yang dapat dipilih saat mengirimkan pesanan. Dengan mendefinisikan daftar kurir sebagai konstanta, kita dapat dengan mudah mengelola dan memperbarui daftar kurir yang tersedia di seluruh aplikasi.
  COURIERS = [ "JNE", "J&T Express", "SiCepat", "AnterAja", "Pos Indonesia", "Ninja Xpress" ].freeze

    # Status pesanan yang dianggap penjualan: sudah dibayar
  LAKU = %w[paid shipped completed].freeze
  scope :laku, -> { where(status: LAKU) }

  # Pesanan yang dibuat dalam N hari terakhir
  scope :dalam_hari, ->(hari) { where(created_at: hari.days.ago..Time.current) }

  # Pesanan yang belum dibayar dan sudah lewat batas waktu.
  # Pesanan yang bukti bayarnya sedang menunggu verifikasi admin tidak ikut.
  scope :expired_unpaid, -> {
    pending
      .where(created_at: ...Rails.configuration.x.payment.deadline_hours.hours.ago)
      .where.not(id: Payment.submitted.select(:order_id))
  }

  validates :recipient_name, :phone, :street, :city, :province, :postal_code, presence: true
  # hanya diperiksa saat admin menandai pesanan dikirim (save dengan context: :ship)
  validate :shipping_info_present, on: :ship


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

    # true kalau pelanggan sudah mengirim bukti bayar dan admin belum memeriksanya.
  # Status pesanan tetap pending sampai admin mengonfirmasi, jadi ini dibaca dari pembayarannya.
  def awaiting_verification?
    pending? && payments.any?(&:submitted?)
  end

   # batas waktu pembayaran; setelah lewat, pesanan dibatalkan otomatis oleh ExpireUnpaidOrdersJob
  def payment_deadline
    created_at + Rails.configuration.x.payment.deadline_hours.hours
  end

  # --- Aksi admin ---------------------------------------------------------
  # Semua method di bawah mengembalikan true kalau berhasil, false kalau
  # status pesanan saat ini tidak mengizinkan aksinya.

  
  # paid -> shipped, dengan kurir dan nomor resi
  def ship(courier:, tracking_number:)
    return false unless paid?

    assign_attributes(
      status: :shipped,
      courier: courier,
      tracking_number: tracking_number.to_s.strip,
      shipped_at: Time.current
    )
    save(context: :ship)
  end


  # shipped -> completed
  def complete
    return false unless shipped?
    completed!
  end

  # pending / paid -> canceled, stok dikembalikan
  def cancel
    hasil = false

    # with_lock: kunci baris pesanan ini, supaya dua admin yang menekan
    # "Batalkan" bersamaan tidak mengembalikan stok dua kali
    with_lock do
      if pending? || paid?
        order_items.includes(:product).order(:product_id).each do |item|
          product = item.product
          product.lock! #kunci supaya produk tidak diubah admin lain bersamaan
          product.update!(stock: product.stock + item.quantity)
        end

        # bukti yang belum diperiksa ikut ditolak supaya tidak menggantung
        payments.submitted.each { |payment| payment.reject!("Pesanan dibatalkan") }

        canceled!
        hasil = true
      end
    end

    hasil
  end

  # Dipakai job. Syaratnya dicek ulang setelah pesanan dikunci, karena sejak
  # job mencari daftar sampai giliran pesanan ini, pelanggan bisa saja baru
  # mengunggah bukti bayar.
  def cancel_if_expired
    with_lock do
      cancel if Order.expired_unpaid.exists?(id: id)
    end
  end

  private
# validasi untuk memastikan bahwa kurir yang dipilih ada dalam daftar COURIERS dan nomor resi tidak kosong. Jika salah satu dari kondisi ini tidak terpenuhi, akan menambahkan pesan kesalahan ke objek pesanan.
def shipping_info_present
  errors.add(:base, "Kurir harus dipilih") unless COURIERS.include?(courier)
  errors.add(:base, "Nomor resi wajib diisi") if tracking_number.blank?
end


end
