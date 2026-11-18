class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :addresses, dependent: :destroy
  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  enum :role, { customer: 0, admin: 1 }
end
