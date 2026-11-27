module PesananTestHelper
  # membuat pesanan berisi satu produk, status bisa diatur (default completed)
  def buat_pesanan(user:, produk:, status: :completed)
    pesanan = Order.create!(
      user: user, status: status, total: produk.price,
      recipient_name: "Budi", phone: "08123456789", street: "Jl. Mawar 1",
      city: "Bandung", province: "Jawa Barat", postal_code: "40111"
    )
    pesanan.order_items.create!(product: produk, product_name: produk.name,
                                quantity: 1, unit_price: produk.price)
    pesanan
  end
end