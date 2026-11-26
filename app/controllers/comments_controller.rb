class CommentsController < ApplicationController
  # batas tulis: 10 komentar per menit per pengguna (polanya sama dengan SessionsController)
  rate_limit to: 10, within: 1.minute, only: :create, by: -> { current_user.id },
    with: -> { redirect_to product_path(params[:product_id], anchor: "diskusi"), alert: "Terlalu banyak komentar. Coba lagi sebentar." }

  def create
    produk = Product.find(params[:product_id])
    # membuat komentar baru dengan atribut yang diterima dari form
    atribut = params.expect(comment: %i[body parent_id])

    parent = nil

    if atribut[:parent_id].present?
      parent = produk.comments.find_by(id: atribut[:parent_id])
      # jika parent tidak ditemukan, beri pesan error dan redirect ke halaman produk
      return ke_diskusi(produk, alert: "Komentar yang dibalas tidak ditemukan.") if parent.nil?
      parent = parent.parent || parent # jika parent punya parent, ambil parentnya (komentar utama)
    end

    komentar = produk.comments.new(body: atribut[:body], user: current_user, parent: parent)
    if komentar.save
      ke_diskusi(produk, notice: "Komentar berhasil dikirim.")
    else
      ke_diskusi(produk, alert: komentar.errors.full_messages.to_sentence)
    end
  end

  private
# ke_diskusi adalah metode privat untuk mengarahkan pengguna ke halaman diskusi produk tertentu dengan pesan tertentu. Metode ini menerima objek produk dan pesan tambahan (seperti notice atau alert) sebagai parameter, lalu melakukan redirect ke URL produk dengan anchor "diskusi" dan menyertakan pesan tersebut.
# **pesan adalah parameter opsional yang memungkinkan kita mengirimkan pesan tambahan (seperti notice atau alert) saat melakukan redirect. Pesan ini akan diteruskan ke metode redirect_to sebagai parameter tambahan.
  def ke_diskusi(produk, **pesan)
    redirect_to product_path(produk, anchor: "diskusi"), **pesan
  end

end
