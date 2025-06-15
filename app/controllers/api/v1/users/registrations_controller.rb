module Api
  module V1
    module Users
      class RegistrationsController < Devise::RegistrationsController
        respond_to :json

        def create
          user = User.new(sign_up_params)

          if user.save
            token = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil).first

            render json: {
              message: "Signed up successfully",
              user: {
                id: user.id,
                email: user.email,
                role: user.role
              },
              token: token
            }, status: :ok
          else
            render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
          end
        end

        private
        
        def sign_up_params
            allowed_roles = ['customer', 'seller']
            role = params.dig(:user, :role)

            role = allowed_roles.include?(role) ? role : 'customer'

            params[:user][:role] = role

            params.require(:user).permit(:email, :password, :password_confirmation, :role)
        end       
      end
    end
  end
end
