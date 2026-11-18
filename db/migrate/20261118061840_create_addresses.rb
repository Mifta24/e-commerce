class CreateAddresses < ActiveRecord::Migration[8.1]
  def change
    create_table :addresses do |t|
      t.references :user, null: false, foreign_key: true
      t.string :recipient_name
      t.string :phone
      t.text :street
      t.string :city
      t.string :province
      t.string :postal_code

      t.timestamps
    end
  end
end
