class Address < ApplicationRecord
  belongs_to :user
  validates :recipient_name, :phone, :street, :city, :province, :postal_code, presence: true
end