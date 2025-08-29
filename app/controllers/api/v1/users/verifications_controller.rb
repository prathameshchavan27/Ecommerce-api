module Api
  module V1
    module Users
      class VerificationsController < ApplicationController
        def verify_email
          @user = User.find_by(email: params[:email], otp_code: params[:otp])
            puts @user.inspect # Debugging line to see user details
          if @user && @user.otp_sent_at > 10.minutes.ago
            @user.update(email_verified: true, otp_code: nil)
            token = Warden::JWTAuth::UserEncoder.new.call(@user, :user, nil).first

            render json: {
              message: "Signed up successfully",
              user: {
                id: @user.id,
                email: @user.email,
                role: @user.role
              },
              token: token
            }, status: :ok
          else # Debugging line to see user details
            @u = User.find(@user.id)
            @u.destroy! # Optional: remove unverified user after OTP expiry
            render json: { error: "Invalid or expired OTP" }, status: :unprocessable_entity
          end
        end
      end
    end
  end
end
