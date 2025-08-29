class UserMailer < ApplicationMailer
    def send_verification_otp
        @user = params[:user]

        mail(
            to: @user.email,
            subject: "Your Verification OTP"
        ) do |format|
            format.text { render plain: "Hi #{@user.email}, your OTP is: #{@user.otp_code}" }
            format.html { render html: "<h2>Hi #{@user.email},</h2><p>Your OTP is: <strong>#{@user.otp_code}</strong></p>".html_safe }
        end
  end
end
