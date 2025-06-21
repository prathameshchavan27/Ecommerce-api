module AuthHelpers
  def auth_headers(user)
    token = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil).first
    {
      'Authorization': "Bearer #{token}",
      'Content-Type': 'application/json'
    }
  end
end

RSpec.configure do |config|
  config.include AuthHelpers
end
