# Antrean moderasi diskusi produk: admin melihat semua komentar, menyembunyikan atau menampilkannya kembali.
class Admin::CommentsController < Admin::BaseController
  def index
    # ?status= hanya dipakai kalau nilainya dikenal (tampil / disembunyikan)
    @status = params[:status].presence_in(Comment.statuses.keys)
    @comments = Comment.includes(:user, :product).order(created_at: :desc, id: :desc)
    @comments = @comments.where(status: @status) if @status
    @comments = @comments.page(params[:page]).per(20)
  end

  def hide
    Comment.find(params[:id]).disembunyikan!
    redirect_back fallback_location: admin_comments_path, notice: "Komentar disembunyikan.", status: :see_other
  end

  def restore
    Comment.find(params[:id]).tampil!
    redirect_back fallback_location: admin_comments_path, notice: "Komentar ditampilkan kembali.", status: :see_other
  end
end