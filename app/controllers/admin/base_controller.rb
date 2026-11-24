# Induk semua controller admin. Karena semuanya mewarisi class ini,
# pengaman admin tidak mungkin terlupa di salah satunya.
class Admin::BaseController < ApplicationController
  before_action :require_admin
  layout "admin" #semua view admin menggunakan layout admin
end
