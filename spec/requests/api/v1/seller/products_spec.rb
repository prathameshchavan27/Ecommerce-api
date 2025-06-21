# spec/requests/api/v1/seller/products_spec.rb

require 'rails_helper'

RSpec.describe 'Api::V1::Seller::Products', type: :request do
  let(:seller) { create(:user, role: 'seller') }
  let(:headers) { auth_headers(seller) }
  let(:category) { create(:category) }

  describe 'POST /api/v1/seller/products' do
    it 'creates a new product' do
      post "/api/v1/seller/products",
        params: {
          product: {
            title: 'Test Product',
            description: 'Some description',
            price: 99.99,
            stock: 10,
            category_id: category.id
          }
        },
        headers: headers,
        as: :json

      expect(response).to have_http_status(:created)
      expect(JSON.parse(response.body)['title']).to eq('Test Product')
    end
  end


end
