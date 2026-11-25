# Pelanggan hanya dilihat (tidak ada ubah/hapus): menghapus pengguna atau mengubah peran
# terlalu berisiko, dan pesanan lama harus tetap punya pemilik.
class Admin::CustomersController < Admin::BaseController
  def index
    # customer saja, bukan admin
    @customers = User.where.not(role: 1). search(params[:q]).dengan_statistik
    @customers =
      if params[:urut] == "belanja"
        @customers.order("total_belanja DESC", "users.id")
      else
        @customers.order("users.created_at DESC", "users.id DESC")
      end
    @customers = @customers.page(params[:page]).per(20)
  end

  def show
    @customer = User.dengan_statistik.find(params[:id])
    @addresses = @customer.addresses.order(:id)
    @orders = @customer.orders.includes(:payments).order(created_at: :desc, id: :desc)
    @jumlah_favorit = @customer.favorites.count
  end
end
