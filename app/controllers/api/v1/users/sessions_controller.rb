module Api
  module V1
    module Users
      class SessionsController < Devise::SessionsController
        respond_to :json

        def create
          user = User.find_for_database_authentication(email: sign_in_params[:email])

          if user&.valid_password?(sign_in_params[:password])
            # DO NOT call sign_in(user) in API-only mode

            token = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil).first

            render json: {
              message: 'Logged in successfully',
              user: {
                id: user.id,
                email: user.email,
                roles: user.roles
              },
              token: token
            }, status: :ok
          else
            render json: { error: 'Invalid email or password' }, status: :unauthorized
          end
        end

        private

        def sign_in_params
          params.require(:user).permit(:email, :password)
        end
      end
    end
  end
end
