require 'rails_helper'

RSpec.describe "Api::V1::Public::Products", type: :request do
  let(:seller) { create(:user, role: 'seller') }
  let(:category) { create(:category) }

  describe "GET /api/v1/public/products" do
    let!(:product) { create(:product, user: seller, category: category) }

    it "returns http success" do
      get "/api/v1/public/products"
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /api/v1/public/products/:id" do
    let!(:product) { create(:product, user: seller, category: category) }

    it "returns http success" do
      get "/api/v1/public/products/#{product.id}"
      expect(response).to have_http_status(:ok)
    end
  end
end
