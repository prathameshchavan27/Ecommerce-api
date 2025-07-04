# spec/requests/api/v1/seller/products_spec.rb

require 'rails_helper'

RSpec.describe 'Api::V1::Seller::Products', type: :request do
  let(:seller) { create(:user, role: 'seller') }
  let(:headers) { auth_headers(seller) }
  let(:category) { create(:category) }
  let!(:product) { create(:product, user: seller, category: category) }

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

  describe 'PUT /api/v1/seller/products/:id' do
    it 'updates the product' do
      put "/api/v1/seller/products/#{product.id}",
        params: {
          product: {
            title: 'New Product',
            description: 'New description',
            price: 99.99,
            stock: 10,
            category_id: category.id
          }
        },
        headers: headers,
        as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body['title']).to eq('New Product')
      expect(body['price']).to eq('99.99')
    end
  end

  describe 'PUT /api/v1/seller/products/:id' do
    let(:seller) { create(:user, role: 'seller') }
    let(:another_seller) { create(:user, role: 'seller') }
    let(:headers) { auth_headers(another_seller) } # logged in as different seller
    let(:category) { create(:category) }
    let!(:product) { create(:product, user: seller, category: category) }

    it 'returns forbidden when user is not the owner' do
      put "/api/v1/seller/products/#{product.id}",
        params: {
          product: {
            title: 'Unauthorized Update'
          }
        },
        headers: headers,
        as: :json

      expect(response).to have_http_status(:forbidden)
      expect(JSON.parse(response.body)['error']).to eq('Forbidden - Not your product')
    end
  end

  describe 'DELETE /api/v1/seller/products/:id' do
    let(:seller) { create(:user, role: 'seller') }
    let(:headers) { auth_headers(seller) }
    it 'delete the product' do
     expect {
        delete "/api/v1/seller/products/#{product.id}",
              headers: headers,
              as: :json
      }.to change(Product, :count).by(-1)

      expect(response).to have_http_status(:ok)
    end
  end

  describe 'DELETE /api/v1/seller/products/:id' do
    let(:seller) { create(:user, role: 'seller') }
    let(:another_seller) { create(:user, role: 'seller') }
    let(:headers) { auth_headers(another_seller) }
    let!(:product) { create(:product, user: seller, category: category) }
    it 'return forbidden when deleting the product not owned by user' do
     expect {
        delete "/api/v1/seller/products/#{product.id}",
              headers: headers,
              as: :json
      }.to change(Product, :count).by(0)

      expect(response).to have_http_status(:forbidden)
    end
  end
end
