json.extract! address, :id, :user_id, :recipient_name, :phone, :street, :city, :province, :postal_code, :created_at, :updated_at
json.url address_url(address, format: :json)
