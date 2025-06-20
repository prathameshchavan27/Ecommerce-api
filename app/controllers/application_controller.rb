class ApplicationController < ActionController::API
  include Devise::Controllers::Helpers  # ✅ required for `current_user`, `authenticate_user!`
  include ActionController::MimeResponds
    rescue_from ActionController::InvalidAuthenticityToken, with: :invalid_token
     respond_to :json
  before_action :skip_flash

  private
def invalid_token
    render json: { error: 'Invalid token' }, status: :unauthorized
  end

  # ✅ Override Devise method for API-only
  def authenticate_user!(opts = {})
    head :unauthorized unless user_signed_in?
  end

  def verify_authenticity_token; end # disables CSRF
  def skip_flash
    request.env["action_dispatch.request.flash_hash"] = nil
  end
end
