class Api::V1::SessionsController < ApplicationController
  include Devise::Controllers::Helpers

  def create
    # @request.env["devise.mapping"] = Devise.mappings[:user]  # <== Add this line!

    user = User.find_for_database_authentication(email: params.dig(:user, :email))
    if user&.valid_password?(params.dig(:user, :password))
      sign_in(:user, user)
      render json: { message: 'Logged in successfully', user: user.as_json(only: [:id, :email, :roles]) }
    else
      render json: { error: 'Invalid email or password' }, status: :unauthorized
    end
  end

  def destroy
    sign_out(:user)
    render json: { message: 'Logged out successfully' }
  end
end
