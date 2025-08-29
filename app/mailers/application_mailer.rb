class ApplicationMailer < ActionMailer::Base
  default from: ENV["GMAIL_USERNAME"] # 👈 use your Gmail from env
  layout "mailer"
end
