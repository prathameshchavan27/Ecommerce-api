require 'rails_helper'

RSpec.describe 'Authentication', type: :request do
  describe 'POST /api/v1/register' do
    it 'registers a new user' do
      post '/api/v1/register', params: {
        user: {
          email: 'testuser@example.com',
          password: 'password123',
          password_confirmation: 'password123',
          role: 'customer'   # you allow only customer
        }
      }

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)

      expect(json["user"]["email"]).to eq('testuser@example.com')
      expect(json["user"]["role"]).to eq('customer')
      expect(json["token"]).not_to be_nil
    end
  end

  describe 'POST /api/v1/login' do
    let(:user) { create(:user) }

    it 'logs in the user' do
      post '/api/v1/login', params: {
        user: {
          email: user.email,
          password: 'password123'
        }
      }

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json["user"]["email"]).to eq(user.email)
      expect(json["token"]).not_to be_nil
    end
  end
end
