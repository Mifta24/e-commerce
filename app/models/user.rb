class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :addresses, dependent: :destroy
  has_one :cart, dependent: :destroy
  has_many :orders, dependent: :restrict_with_error
  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true
  # validasi untuk memastikan bahwa password memiliki panjang minimal 6 karakter, tetapi hanya diterapkan saat membuat pengguna baru atau saat mengubah password. Jika password tidak diisi, validasi ini diabaikan.
  validates :password, length: { minimum: 6 }, if: -> { new_record? || !password.nil? }, allow_nil: true

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  enum :role, { customer: 0, admin: 1 }
end
