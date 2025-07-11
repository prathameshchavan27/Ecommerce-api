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

  #======================================================
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

  describe 'POST /api/v1/customer/orders/:id/cancel' do
    # These `let` definitions are scoped to this `describe` block.
    # They will use your existing `customer`, `seller`, `category` from the outer scope.
    let(:headers)  { auth_headers(customer) }
    context 'when the order is cancellable (placed)' do
      # Create a specific order for this context, ensuring enough products are created
      let!(:cancellable_order_placed) { create(:order, user: customer, status: :placed, products_count: 1, product_quantity: 3) }
      # Calculate initial product stock by reloading the product and adding back the quantity deducted by the order factory
      let!(:initial_product_stock_placed) { cancellable_order_placed.order_items.first.product.reload.stock + cancellable_order_placed.order_items.first.quantity }

      before do
        post "/api/v1/customer/orders/#{cancellable_order_placed.id}/cancel", headers: headers
        cancellable_order_placed.reload # Reload the order to get its updated status from DB
      end

      it 'returns a 200 OK status' do
        expect(response).to have_http_status(:ok)
      end

      it 'updates the order status to cancelled' do
        expect(cancellable_order_placed.status).to eq('cancelled')
      end

      it 'restocks the products' do
        product = cancellable_order_placed.order_items.first.product.reload # Reload the product directly
        expect(product.stock).to eq(initial_product_stock_placed)
      end

      it 'returns a success message' do
        expect(json_response['message']).to include("Order ##{cancellable_order_placed.id} has been cancelled")
      end

      it 'returns the cancelled order details' do
        expect(json_response['order']['id']).to eq(cancellable_order_placed.id)
        expect(json_response['order']['status']).to eq('cancelled')
        expect(json_response['order']['order_items'].count).to eq(cancellable_order_placed.order_items.count)
      end
    end

    context 'when the order is cancellable (processed)' do
      let!(:cancellable_order_processed) { create(:order, user: customer, status: :processed, products_count: 1, product_quantity: 2) }
      let!(:initial_product_stock_processed) { cancellable_order_processed.order_items.first.product.reload.stock + cancellable_order_processed.order_items.first.quantity }

      before do
        post "/api/v1/customer/orders/#{cancellable_order_processed.id}/cancel", headers: headers
        cancellable_order_processed.reload
      end

      it 'returns a 200 OK status' do
        expect(response).to have_http_status(:ok)
      end

      it 'updates the order status to cancelled' do
        expect(cancellable_order_processed.status).to eq('cancelled')
      end

      it 'restocks the products' do
        product = cancellable_order_processed.order_items.first.product.reload
        expect(product.stock).to eq(initial_product_stock_processed)
      end
    end

    context 'when the order is not cancellable (shipped)' do
      let!(:non_cancellable_order) { create(:order, user: customer, status: :shipped) }

      before do
        post "/api/v1/customer/orders/#{non_cancellable_order.id}/cancel", headers: headers
        non_cancellable_order.reload
      end

      it 'returns a 422 Unprocessable Entity status' do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'does not change the order status' do
        expect(non_cancellable_order.status).to eq('shipped')
      end

      it 'returns an error message' do
        expect(json_response['error']).to include('Order cannot be cancelled')
      end
    end

    context 'when the order does not exist' do
      let(:non_existent_id) { 99999 }

      before do
        post "/api/v1/customer/orders/#{non_existent_id}/cancel", headers: headers
      end

      it 'returns a 404 Not Found status' do
        expect(response).to have_http_status(:not_found)
      end

      it 'returns an error message' do
        expect(json_response['error']).to include('Order not found')
      end
    end

    context 'when the user is not authorized (no headers)' do
      # Create an order that exists so the route is valid, even if auth fails
      let!(:order_to_cancel_unauthorized) { create(:order) }

      before do
        post "/api/v1/customer/orders/#{order_to_cancel_unauthorized.id}/cancel", headers: {} # No headers provided
      end

      it 'returns a 403 Forbidden status' do
        expect(response).to have_http_status(:unauthorized)
      end

      # it 'returns an error message' do
      #   expect(json_response['error']).to include('You need to login as a customer')
      # end
    end

    context 'when an order belongs to another customer' do
      let!(:another_customer) { create(:user, role: 'customer') }
      let!(:another_order) { create(:order, user: another_customer, status: :placed) }
      # The `customer` from the outer `let` is trying to cancel `another_order`

      before do
        post "/api/v1/customer/orders/#{another_order.id}/cancel", headers: headers
      end

      it 'returns a 404 Not Found status' do
        expect(response).to have_http_status(:not_found)
      end

      it 'returns an error message' do
        expect(json_response['error']).to include('Order not found')
      end

      it 'does not change the other customer\'s order status' do
        another_order.reload
        expect(another_order.status).to eq('placed')
      end
    end
  end
  # Helper to parse JSON response body
  def json_response
    JSON.parse(response.body)
  end
end
