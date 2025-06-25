require 'rails_helper'

RSpec.describe "Api::V1::Customer::Carts", type: :request do
  let(:customer) { create(:user, role: 'customer') }
  let(:seller)   { create(:user, role: 'seller') }
  let(:category) { create(:category) }
  let(:product)  { create(:product, user: seller, category: category) }
  let(:headers)  { auth_headers(customer) }

  before do
    @cart = customer.create_cart
    @cart.cart_items.create(product_id: product.id, quantity: 2)
  end

  describe "GET /api/v1/customer/cart" do
    it "returns the cart details for the logged-in customer" do
      get "/api/v1/customer/cart", headers: headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      expect(json["cart"]["user_id"]).to eq(customer.id)
      expect(json["cart"]["items"].length).to eq(1)
      expect(json["cart"]["items"].first["product_id"]).to eq(product.id)
      expect(json["cart"]["total_price"]).to eq((product.price * 2).to_f.to_s)
    end
  end
end
