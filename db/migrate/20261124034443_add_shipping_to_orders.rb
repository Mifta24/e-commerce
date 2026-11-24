class AddShippingToOrders < ActiveRecord::Migration[8.1]
  def change
    add_column :orders, :courier, :string
    add_column :orders, :tracking_number, :string
    add_column :orders, :shipped_at, :datetime
  end
end
