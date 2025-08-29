module Api
  module V1
    module Users
      class RegistrationsController < Devise::RegistrationsController
        respond_to :json

        def create
            Rails.logger.debug "⚠️ Incoming sign_up_params: #{sign_up_params.inspect}"
          user = User.new(sign_up_params)
          user.email_verified = false # Default to false; implement email verification later
          user.otp_code = rand(100000..999999).to_s # Generate a 6-character hex code
          user.otp_sent_at = Time.current
          if user.save
            UserMailer.with(user: user).send_verification_otp.deliver_now
            render json: {
              message: "Please verify your email with the OTP sent before logging in."
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
            allowed_roles = [ "customer", "seller" ]
            user_params = params.require(:user).permit(:email, :password, :password_confirmation, :role).to_h

            # Force-safe: remove unexpected keys
            user_params = user_params.slice("email", "password", "password_confirmation", "role")

            user_params["role"] = allowed_roles.include?(user_params["role"]) ? user_params["role"] : "customer"
            user_params
        end
      end
    end
  end
end
