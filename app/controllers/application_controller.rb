class ApplicationController < ActionController::API
  # Disable flash messages for API
  before_action :skip_flash

  private

  def skip_flash
    request.env["action_dispatch.request.flash_hash"] = nil
  end
end
