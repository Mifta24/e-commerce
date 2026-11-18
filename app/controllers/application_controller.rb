class ApplicationController < ActionController::Base
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  helper_method :current_user, :admin?

  private

  def current_user = Current.user
  def admin? = current_user&.admin?

  def require_admin
    redirect_to root_path, alert: "Anda tidak punya akses." unless admin?
  end
  
  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes
end
