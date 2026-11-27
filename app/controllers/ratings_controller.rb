class RatingsController < ApplicationController
  # batas tulis dalam satu menit: 10 rating per pengguna
  rate_limit to: 10, within: 1.minute, only: %i[create update], by: -> { current_user.id },
  # jika batas terlampaui, redirect ke halaman produk dengan anchor "rating" dan menampilkan pesan alert
  # anchor itu dibuat  untuk menandai bagian rating di halaman produk, sehingga pengguna diarahkan langsung ke bagian tersebut.
  with: -> { redirect_to product_path(params[:product_id], anchor: "rating"), alert: "Terlalu banyak rating. Coba lagi sebentar." }

  before_action :set_product

  def create
    rating = current_user.ratings.new(product: @product, stars: nilai_rating)
    if rating.save
      ke_rating(notice: "Rating berhasil dikirim.")
    else
      ke_rating(alert: rating.errors.full_messages.to_sentence)
    end
  end

  def update 
    rating = current_user.ratings.find_by(product: @product)
    return ke_rating(alert: "Rating tidak ditemukan.") if rating.nil?

    if rating.update(stars: nilai_rating)
      ke_rating(notice: "Rating berhasil diperbarui.")
    else
      ke_rating(alert: rating.errors.full_messages.to_sentence)
    end
  end

  private
  def set_product
    @product = Product.find(params[:product_id])
  end

  # nilai mentah, jangan di -to_i, "4.5" lolos menajdoi 4
  def nilai_rating
    # digunakan untuk mengekstrak nilai bintang dari parameter yang diterima dari form. 
    # Metode ini mengharapkan parameter dengan struktur tertentu, yaitu params[:rating][:stars]. 
    # Dengan menggunakan params.expect, kita memastikan bahwa hanya parameter yang diharapkan yang akan diambil, 
    # sehingga mengurangi risiko kesalahan atau manipulasi data.
    params.expect(rating: [ :stars ])[:stars]
  end

  def ke_rating(**pesan)
    # digunakan untuk mengarahkan pengguna kembali ke halaman produk tertentu dengan anchor "rating" dan menyertakan pesan tambahan (seperti notice atau alert). 
    # Metode ini menerima parameter tambahan (**pesan) yang memungkinkan kita mengirimkan pesan tambahan saat melakukan redirect. 
    # Pesan ini akan diteruskan ke metode redirect_to sebagai parameter tambahan.
    redirect_to product_path(@product, anchor: "rating"), **pesan
  end
end
