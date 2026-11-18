class AddProfileToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :name, :string, null: false
    add_column :users, :role, :integer, null: false, default: 0
    add_column :users, :phone, :string
  end
end
