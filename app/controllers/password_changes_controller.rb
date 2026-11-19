class PasswordChangesController < ApplicationController
  rate_limit to: 5, within: 3.minutes, only: :update,
             with: -> { redirect_to edit_password_change_path, alert: "Terlalu banyak percobaan. Coba lagi nanti." }

  def edit
    @user = current_user
  end

  def update
    @user = current_user

    if !@user.authenticate(params[:current_password].to_s)
      flash.now[:alert] = "Password saat ini salah."
      render :edit, status: :unprocessable_content
    elsif password_params[:password].blank?
      flash.now[:alert] = "Password baru tidak boleh kosong."
      render :edit, status: :unprocessable_content
    elsif @user.update(password_params)
      # keluarkan login di perangkat lain, sisakan yang sedang dipakai
      @user.sessions.where.not(id: Current.session.id).destroy_all
      redirect_to profile_path, notice: "Password berhasil diubah."
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  def password_params
    params.expect(user: [ :password, :password_confirmation ])
  end
end
