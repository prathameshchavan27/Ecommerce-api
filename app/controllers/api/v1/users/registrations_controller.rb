module Api
  module V1
    module Users
      class RegistrationsController < Devise::RegistrationsController
        respond_to :json

        def create
            Rails.logger.debug "⚠️ Incoming sign_up_params: #{sign_up_params.inspect}"

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

        # def sign_up_params
        # #   allowed_roles = ['customer', 'seller']
        #   user_params = params.require(:user).permit(:email, :password, :password_confirmation, :role)

        # #   user_params[:role] = allowed_roles.include?(user_params[:role]) ? user_params[:role] : 'customer'
        #   user_params
        # end
        def sign_up_params
            allowed_roles = ['customer', 'seller']
            user_params = params.require(:user).permit(:email, :password, :password_confirmation, :role).to_h

            # Force-safe: remove unexpected keys
            user_params = user_params.slice('email', 'password', 'password_confirmation', 'role')

            user_params['role'] = allowed_roles.include?(user_params['role']) ? user_params['role'] : 'customer'
            user_params
        end

      end
    end
  end
end
