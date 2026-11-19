class ApplicationController < ActionController::Base
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  helper_method :current_user, :admin?, :current_cart

  private

  def current_user 
    resume_session
     Current.user
  end

  def admin? = current_user&.admin?

   
  def current_cart
    @current_cart ||=
      if current_user
        current_user.cart
      elsif cookies.signed[:cart_token]
        Cart.find_by(token: cookies.signed[:cart_token], user_id: nil)
      end
  end

  def current_cart!
    @current_cart ||= current_cart || create_cart
  end

  def create_cart
    if current_user
      current_user.create_cart!
    else
      Cart.create!.tap do |cart|
        cookies.signed[:cart_token] = { value: cart.token, expires: 1.year.from_now }
      end
    end
  end

  def merge_guest_cart_into(user)
    token = cookies.signed[:cart_token]
    return if token.blank?

    guest_cart = Cart.find_by(token: token, user_id: nil)

    if guest_cart
      if user.cart
        user.cart.absorb(guest_cart)
      else
        guest_cart.update!(user: user)
      end
    end

  end

  def require_admin
    redirect_to root_path, alert: "Anda tidak punya akses." unless admin?
  end
  
  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes
end
