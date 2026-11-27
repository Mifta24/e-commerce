class Comment < ApplicationRecord
  MAX_BODY = 1000

  belongs_to :user
  belongs_to :product
  # optional true krena komentar pertama gak punya parent
  belongs_to :parent, class_name: "Comment", optional: true

  has_many :replies, -> { order(:created_at, :id) },
                      class_name: "Comment", foreign_key: "parent_id",
                      # inverse_of untuk menhubungkan replies dengan parent agar bisa mengakses parent dari replies dan sebaliknya.
                      inverse_of: :parent, dependent: :destroy

  enum :status, { tampil: 0, disembunyikan: 1 }

  validates :body, presence: true, length: { maximum: MAX_BODY }
  validate :parent_product_must_match

  # scope utama dibuat untuk mengambil komentar yang tidak memiliki induk (parent_id: nil), sehingga hanya komentar utama yang dikembalikan.
  scope :utama, -> { where(parent_id: nil) }

  private

  # parent harus komentar utama dari produk yg sama
  def parent_product_must_match
    return if parent.nil? # jika parent nil, tidak perlu validasi

    errors.add(:parent, "harus komentar utama dari produk yang sama") if parent.product_id != product_id

    errors.add(:parent, "tidak boleh balasan ke balasan") if parent.parent_id.present?
  end
end
