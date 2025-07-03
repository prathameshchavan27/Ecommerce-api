require 'rails_helper'

# RSpec.describe "Api::V1::Customer::Orders", type: :job do #switching between background job and request test
RSpec.describe "Api::V1::Customer::Orders", type: :request do
  let(:customer) { create(:user, role: 'customer') }
  let(:seller) { create(:user, role: 'seller') }
  let(:category) { create(:category) }
  let(:product) { create(:product, user: seller, category: category, stock: 10, price: 100) }

  # commented block is test for order creation and related. only run commented or uncommented block at a time to avoid seeing errors
  # before do
  #   cart = customer.create_cart
  #   cart.cart_items.create(product: product, quantity: 2)
  # end

  # it "creates an order and reduces stock after successful checkout" do
  #   expect {
  #     Orders::ProcessOrderJob.perform_now(customer.id)
  #   }.to change { Order.count }.by(1)
  #    .and change { OrderItem.count }.by(1)
  #    .and change { product.reload.stock }.from(10).to(8)

  #   order = customer.orders.last
  #   expect(order.total_price).to eq(200)
  #   expect(order.status).to eq("placed")
  # end

  # it "does not create an order if stock is insufficient" do
  #   product.update(stock: 1)

  #   expect {
  #     expect {
  #       Orders::ProcessOrderJob.perform_now(customer.id)
  #     }.to raise_error(RuntimeError, /Insufficient stock/)
  #   }.to_not change { Order.count }

  #   expect(product.reload.stock).to eq(1)
  # end

  # it "clears the cart after checkout" do
  #   puts "Cart items before: #{customer.cart.cart_items.count}"
  #   Orders::ProcessOrderJob.perform_now(customer.id)
  #   puts "Cart items after: #{customer.reload.cart.cart_items.count}"
  #   expect(customer.cart.cart_items).to be_empty
  # end

  describe "when product is in stock and quantity is valid" do
    let(:product) { create(:product, user: seller, category: category, stock: 10, price: 100) }
    let(:headers)  { auth_headers(customer) }
    it "creates an order and reduces stock" do
      expect {
        post "/api/v1/customer/orders/direct_checkout",
          params: { product_id: product.id, quantity: 2 },
          headers: headers,
          as: :json
      }.to change { Order.count }.by(1)
        .and change { OrderItem.count }.by(1)

      expect(response).to have_http_status(:created)
      expect(product.reload.stock).to eq(8)
      json = JSON.parse(response.body)
      expect(json["message"]).to eq("Order placed successfully")
    end
  end

  describe "when product is out of stock" do
    let(:product) { create(:product, user: seller, category: category, stock: 10, price: 100) }
    let(:headers)  { auth_headers(customer) }
    it "does not create order and returns error" do
      post "/api/v1/customer/orders/direct_checkout",
        params: { product_id: product.id, quantity: 20 },
        headers: headers,
        as: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("Product out of stock")
      expect(Order.count).to eq(0)
    end
  end


end
