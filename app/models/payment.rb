class Payment < ApplicationRecord
  belongs_to :order
  has_one_attached :proof

  enum :status, { submitted: 0, confirmed: 1, rejected: 2 }
  BANKS = ["BCA", "BNI", "BRI", "Mandiri", "CIMB Niaga", "Permata", "Danamon", "Bank Jago", "Bank Syariah Indonesia", "Bank Muamalat", "Bank Mega", "Bank Panin", "Bank OCBC NISP", "Bank Maybank", "Bank Commonwealth", "Bank UOB Indonesia"]

  validates :amount, numericality: { only_integer: true, greater_than: 0 }
  validates :sender_name, :sender_bank, presence: true
  validates :proof, presence: { message: "harus diunggah" }
  validates :note, presence: { message: "harus diisi saat menolak" }, if: -> { rejected? }
  validate :proof_must_be_valid

  # admin konfirmasi pemayaran pesanan jadi paid statusnya
  def confirm!
    transaction do
      update!(status: :confirmed, reviewed_at: Time.current)
      order.update!(status: :paid)
    end
  end

  # admin menolak pemayaran 
  def reject!(reason)
    transaction do
      update!(status: :rejected, note: reason, reviewed_at: Time.current)
    end
  end
  
  private

  def proof_must_be_valid
    return unless proof.attached?

    unless %w[image/jpeg image/png image/webp].include?(proof.content_type)
      errors.add(:proof, "harus berformat JPG, PNG, atau WebP")
    end

    if proof.byte_size > 5.megabytes
      errors.add(:proof, "maksimal 5 MB")
    end
  end
end
