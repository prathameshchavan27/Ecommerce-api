require 'rails_helper'

RSpec.describe "Api::V1::Customer::Orders", type: :job do
  let(:customer) { create(:user, role: 'customer') }
  let(:seller) { create(:user, role: 'seller') }
  let(:category) { create(:category) }
  let(:product) { create(:product, user: seller, category: category, stock: 10, price: 100) }

  before do
    cart = customer.create_cart
    cart.cart_items.create(product: product, quantity: 2)
  end

  it "creates an order and reduces stock after successful checkout" do
    expect {
      Orders::ProcessOrderJob.perform_now(customer.id)
    }.to change { Order.count }.by(1)
     .and change { OrderItem.count }.by(1)
     .and change { product.reload.stock }.from(10).to(8)

    order = customer.orders.last
    expect(order.total_price).to eq(200)
    expect(order.status).to eq("placed")
  end

  it "does not create an order if stock is insufficient" do
    product.update(stock: 1)

    expect {
      expect {
        Orders::ProcessOrderJob.perform_now(customer.id)
      }.to raise_error(RuntimeError, /Insufficient stock/)
    }.to_not change { Order.count }

    expect(product.reload.stock).to eq(1)
  end

  it "clears the cart after checkout" do
    puts "Cart items before: #{customer.cart.cart_items.count}"
    Orders::ProcessOrderJob.perform_now(customer.id)
    puts "Cart items after: #{customer.reload.cart.cart_items.count}"
    expect(customer.cart.cart_items).to be_empty
  end
end
