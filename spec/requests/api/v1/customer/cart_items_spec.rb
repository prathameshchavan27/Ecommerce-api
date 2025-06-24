require 'rails_helper'

RSpec.describe "Api::V1::Customer::CartItems", type: :request do
  let(:customer) { create(:user, role: 'customer') }
  let(:seller) { create(:user, role: 'seller') }
  let(:category) { create(:category) }
  let!(:product) { create(:product, user: seller, category: category) }
  let(:headers)  { auth_headers(customer) }

  describe "POST /api/v1/customer/cart_items" do
    it "adds a product to the cart and returns serialized cart data" do
      post "/api/v1/customer/cart_items",
        params: { product_id: product.id, quantity: 2 },
        headers: headers,
        as: :json

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      puts "#{customer.id} #{json["cart_item"]["user_id"]}"
      puts json
      expect(json["cart_item"]["user_id"]).to eq(customer.id)
      expect(json["cart_item"]["items"].length).to eq(1)
      expect(json["cart_item"]["items"].first["product_id"]).to eq(product.id)
      expect(json["cart_item"]["items"].first["quantity"]).to eq(2)
      expect(json["cart_item"]["total_price"].to_f).to eq((product.price * 2).to_f)
    end
  end
end
