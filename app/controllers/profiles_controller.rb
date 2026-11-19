class ProfilesController < ApplicationController
  before_action :set_user

  def show
  end

  def edit
  end

  def update
    if @user.update(profile_params)
      redirect_to profile_path, notice: "Profil berhasil diperbarui."
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  # objek baru dari database, terpisah dari yang dipakai navbar,
  # supaya nama di navbar tidak ikut berubah kalau penyimpanan gagal
  def set_user
    @user = User.find(current_user.id)
  end

  def profile_params
    params.expect(user: [ :name, :phone ])
  end
end
