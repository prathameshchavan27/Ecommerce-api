FactoryBot.define do
  factory :order do
    user { association :user, role: :customer } # Order belongs to a customer
    total_price { 0.0 } # Will be updated by order_items
    status { :placed } # <--- FIX 2: Set a valid default status. Use :placed or "placed".

    # FIX 1: Define transient attributes here
    transient do
      products_count { 1 } # Number of products to add to this order
      product_quantity { 2 } # Default quantity for each product in the order
    end

    # Callback to create order items after the order is created
    after(:create) do |order, evaluator|
      evaluator.products_count.times do
        # Ensure product creation uses `seller` and `category` if required by your Product model
        # Also ensure enough stock is available before product stock is reduced by order item.
        product = create(:product, user: order.user.role == "seller" ? order.user : create(:user, role: :seller), category: create(:category), stock: evaluator.product_quantity + 5)
        create(:order_item, order: order, product: product, quantity: evaluator.product_quantity, price: product.price)
      end
      # Recalculate total price based on created order items
      order.update(total_price: order.order_items.sum { |item| item.price * item.quantity })
      # Subtract stock from products (do this AFTER order items are created and product is reloaded)
      order.order_items.each do |item|
        # Reload product to ensure we decrement its latest stock
        item.product.reload.decrement!(:stock, item.quantity)
      end
    end

    # Traits for different order statuses (optional but good practice)
    trait :placed do
      status { :placed }
    end

    trait :processed do
      status { :processed }
    end

    trait :shipped do
      status { :shipped }
    end

    trait :delivered do
      status { :delivered }
    end

    trait :cancelled do
      status { :cancelled }
    end
  end
end
