class Cart < ApplicationRecord
  belongs_to :user, optional: true
  has_secure_token :token
end
