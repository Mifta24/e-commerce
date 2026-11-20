class CreatePayments < ActiveRecord::Migration[8.1]
  def change
    create_table :payments do |t|
      t.references :order, null: false, foreign_key: true
      t.integer  :amount, null: false
      t.string   :sender_name, null: false
      t.string   :sender_bank, null: false
      t.integer  :status, null: false, default: 0
      t.text     :note
      t.datetime :reviewed_at

      t.timestamps

      t.check_constraint "amount >= 0", name: "payments_amount_not_negative"
      # satu pesanan hanya boleh punya SATU pembayaran yang "aktif"
      # (submitted atau confirmed). Yang ditolak (2) tidak dihitung.
      t.index :order_id, unique: true, where: "status IN (0, 1)",
              name: "index_payments_one_active_per_order"
    end
  end
end
