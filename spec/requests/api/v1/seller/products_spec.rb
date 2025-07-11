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

  def json_response
    JSON.parse(response.body)
  end

  describe 'PATCH /api/v1/seller/products/:id/adjust_stock' do
    let(:seller) { create(:user, role: 'seller') }
    let(:another_seller) { create(:user, role: 'seller') }
    # let(:auth_headers) { auth_headers(seller) }
    let!(:product) { create(:product, user: seller, category: category, stock: 100) }

    context 'when increasing stock' do
      # let(:headers) { auth_headers(seller) }
      it 'successfully increases product stock' do
        expect do
          patch "/api/v1/seller/products/#{product.id}/adjust_stock",
                params: { change_quantity: 50 },
                headers: headers,
                as: :json
        end.to change { product.reload.stock }.from(100).to(150)

        expect(response).to have_http_status(:ok)
        expect(json_response['message']).to eq('Product stock updated successfully.')
        expect(json_response['product']['stock']).to eq(150)
      end
    end

    context 'when decreasing stock within limits' do
      it 'successfully decreases product stock' do
        expect do
          patch "/api/v1/seller/products/#{product.id}/adjust_stock",
                params: { change_quantity: -20 },
                headers: headers,
                as: :json
        end.to change { product.reload.stock }.from(100).to(80)

        expect(response).to have_http_status(:ok)
        expect(json_response['message']).to eq('Product stock updated successfully.')
        expect(json_response['product']['stock']).to eq(80)
      end
    end

    context 'when decreasing stock below zero' do
      it 'returns an unprocessable entity error and does not change stock' do
        expect do
          patch "/api/v1/seller/products/#{product.id}/adjust_stock",
                params: { change_quantity: -120 }, # Try to decrease by more than available
                headers: headers,
                as: :json
        end.to_not change { product.reload.stock }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['error']).to include('Not enough stock for product')
        expect(product.reload.stock).to eq(100) # Stock should remain unchanged
      end
    end

    context 'when change_quantity is zero' do
      it 'returns an unprocessable entity error' do
        expect do
          patch "/api/v1/seller/products/#{product.id}/adjust_stock",
                params: { change_quantity: 0 },
                headers: headers,
                as: :json
        end.to_not change { product.reload.stock }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['error']).to eq('Change quantity must not be zero.')
      end
    end

    context 'when product does not exist' do
      let(:non_existent_id) { 99999 }

      it 'returns a not found error' do
        patch "/api/v1/seller/products/#{non_existent_id}/adjust_stock",
              params: { change_quantity: 10 },
              headers: headers,
              as: :json

        expect(response).to have_http_status(:not_found)
        expect(json_response['error']).to include('Product not found')
      end
    end

    context 'when product belongs to another seller' do
      let!(:another_seller) { create(:user, role: 'seller') }
      let!(:another_product) { create(:product, user: another_seller, category: category, stock: 50) }

      it 'returns a not found error and does not adjust stock' do
        expect do
          patch "/api/v1/seller/products/#{another_product.id}/adjust_stock",
                params: { change_quantity: 10 },
                headers: headers, # Authenticated as original seller
                as: :json
        end.to_not change { another_product.reload.stock }

        expect(response).to have_http_status(:not_found)
        expect(json_response['error']).to include("Product not found or you don't have permimssion to adjust stock")
      end
    end

    context 'when user is not authorized (not a seller)' do
      let(:customer_user) { create(:user, role: 'customer') }
      let(:customer_headers) { auth_headers(customer_user) } # Auth as customer

      it 'returns a forbidden error' do
        expect do
          patch "/api/v1/seller/products/#{product.id}/adjust_stock",
                params: { change_quantity: 10 },
                headers: customer_headers,
                as: :json
        end.to_not change { product.reload.stock }

        expect(response).to have_http_status(:forbidden)
        expect(json_response['error']).to include('Forbidden - Sellers only') # Or whatever your `authorize_seller!` renders
      end
    end
  end
end
