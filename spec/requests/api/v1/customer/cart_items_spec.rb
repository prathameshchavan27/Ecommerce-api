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


  describe "PATCH /api/v1/customer/cart_items/:id" do
    let!(:cart)     { customer.create_cart }
    let!(:cart_item) { cart.cart_items.create(product: product, quantity: 2) }
    it "updates the quantity of the cart item" do
      patch "/api/v1/customer/cart_items/#{cart_item.id}",
        params: { quantity: 5 },
        headers: headers,
        as: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      puts json["cart_item"]
      expect(json["cart_item"]["quantity"]).to eq(5)
    end
  end

  describe "PATCH /api/v1/customer/cart_items/:id" do
    let!(:cart)     { customer.create_cart }
    let!(:cart_item) { cart.cart_items.create(product: product, quantity: 2) }
    let(:headers)  { auth_headers(seller) }
    it "return forbidden when other user tries to update the cart item" do
      patch "/api/v1/customer/cart_items/#{cart_item.id}",
        params: { quantity: 5 },
        headers: headers,
        as: :json

      expect(response).to have_http_status(:forbidden)
      # json = JSON.parse(response.body)
      # puts json["cart_item"]
      # expect(json["cart_item"]["quantity"]).to eq(5)
    end
  end

  describe "PATCH /api/v1/customer/cart_items/:id" do
    let!(:cart)      { customer.create_cart }
    let!(:cart_item) { cart.cart_items.create(product: product, quantity: 2) }
    let(:headers)    { auth_headers(customer) }

    it "returns error when quantity is 0 instead of deleting the item" do
      patch "/api/v1/customer/cart_items/#{cart_item.id}",
        params: { quantity: 0 },
        headers: headers,
        as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)

      expect(json["errors"]).to include("Quantity must be greater than 0")
      expect(CartItem.exists?(cart_item.id)).to be true
    end
  end

  describe "DELETE /api/v1/customer/cart_items/:id" do
    let!(:cart)       { customer.create_cart }
    let!(:cart_item)  { cart.cart_items.create(product: product, quantity: 2) }

    it "deletes the cart item for the logged-in customer" do
      delete "/api/v1/customer/cart_items/#{cart_item.id}", headers: headers

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["message"]).to eq("Item removed from cart")
      expect(cart.cart_items.find_by(id: cart_item.id)).to be_nil
    end

    it "returns not found if cart item does not belong to the user" do
      other_user = create(:user, role: 'customer')
      other_headers = auth_headers(other_user)

      delete "/api/v1/customer/cart_items/#{cart_item.id}", headers: other_headers

      expect(response).to have_http_status(:unprocessable_entity) # Or :unprocessable_entity depending on your logic
      expect(JSON.parse(response.body)["errors"]).to include("Cart item not found")
    end
  end
end
