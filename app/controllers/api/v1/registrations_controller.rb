class Api::V1::RegistrationsController < ApplicationController
  # POST /api/v1/signup
  def create
    user = User.new(signup_params)
    user.roles = [:user] # default role

    if user.save
      render json: { message: 'User created successfully' }, status: :created
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def signup_params
    params.require(:user).permit(:email, :password, :password_confirmation)
  end
end
