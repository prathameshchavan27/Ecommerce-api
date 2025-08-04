require "stripe"
class Api::V1::Customer::OrdersController < Api::V1::BaseController
    before_action :authorize_customer!

    def create
        cart = @current_user.cart
        return render_error("Cart is empty", :bad_request) if cart.blank? || cart.cart_items.blank?

        payment_token = params[:payment_token]

        # Use a transaction to ensure all database ops are atomic
        ActiveRecord::Base.transaction do
            # 1. Reserve stock for all cart items
            cart.cart_items.includes(:product).each do |cart_item|
                cart_item.product.reserve_stock(cart_item.quantity)
            end

            # 2. Create the pending order
            @pending_order = @current_user.orders.create!(
                total_price: cart.cart_items.sum { |item| item.quantity * item.product.price },
                status: :pending
            )

            # 3. Make the synchronous Stripe API call
            payment_intent = Stripe::PaymentIntent.create(
                amount: (@pending_order.total_price * 100).to_i,
                currency: "usd",
                payment_method: payment_token,
                confirm: true,
                return_url: "http://localhost:3001/",
                metadata: { order_id: @pending_order.id }
            )

            # 4. Check the payment result
            if payment_intent.status == "succeeded"
                # Payment was successful. Queue the job to finalize the order.
                cart.cart_items.each do |cart_item|
                    product = cart_item.product
                    quantity = cart_item.quantity
                    @pending_order.order_items.create!(
                        product: product,
                        quantity: quantity,
                        price: product.price
                    )
                end
                Payment.create!(
                    order: @pending_order,
                    amount: @pending_order.total_price, # Use the amount from Stripe's object (in cents)
                    currency: payment_intent.currency,
                    status: payment_intent.status,
                    stripe_payment_intent_id: payment_intent.id # Store the Stripe ID
                )
                Orders::ProcessOrderJob.perform_later(@pending_order.id)
                render json: { message: "Order is being processed!" }, status: :accepted
            else
                # Payment failed. The transaction will be rolled back, and reserved stock released.
                raise "Stripe payment failed with status: #{payment_intent.status}"
            end
        end

    rescue Product::InsufficientStockError => e
        raise "#{e.message}", :ok
    rescue Stripe::CardError => e
        raise "#{e.error.message}", :bad_request
    rescue StandardError => e
        raise "Payment failed. #{e.message}", :unprocessable_entity
    end

    def direct_checkout
        requested_quantity = params[:quantity].to_i
        payment_token = params[:payment_token]
        product = Product.where(id: params[:product_id])
                        .where("stock >= ?", requested_quantity)
                        .first

        if product.nil?
            render json: { error: "Product out of stock" }, status: :ok
            return
        end

        ActiveRecord::Base.transaction do
            product.reserve_stock(requested_quantity)

            @order = @current_user.orders.create!(
                total_price: product.price.to_i * requested_quantity,
                status: :pending
            )

            payment_intent = Stripe::PaymentIntent.create(
                amount: (@order.total_price * 100).to_i,
                currency: "usd",
                payment_method: payment_token,
                confirm: true,
                return_url: "http://localhost:3001/",
                metadata: { order_id: @pending_order.id }
            )
            if payment_intent.status == "succeeded"
                @order.order_items.create!(
                    product: product,
                    quantity: requested_quantity,
                    price: product.price
                )
                @order.order_items.first.confirm_reservation_and_sell(requested_quantity)
                @order.update!(status: :placed)
            end
        end

        render json: { message: "Order placed successfully", order: @order }, status: :created
    end

    def cancel
        begin
            @order = @current_user.orders.find_by(id: params[:id])

            if @order.nil?
                render json: { error: "Order not found" }, status: :not_found
                return
            end

            if @order.cancel!
                render json: {
                    message: "Order ##{@order.id} has been cancelled ad product stock restocked.",
                    order: @order.as_json(include: :order_items)
                }, status: :ok
            else
                render json: { error: @order.errors.full_messages.to_sentence }, status: :unprocessable_entity
            end
        rescue ActiveRecord::RecordNotFound # Catch if find_by was changed to find! and ID is bad
            render json: { error: "Order not found." }, status: :not_found
        rescue StandardError => e
            # Catch any unexpected errors that might escape the transaction block
            render json: { error: "An unexpected error occurred: #{e.message}" }, status: :internal_server_error
        end
    end

    private
    def order_params
        params.require(:order_item).permit(:product_id, :quantity)
    end

    def authorize_customer!
        Rails.logger.debug "💬 role = #{@current_user&.role.inspect}"
        unless @current_user&.role == :customer
            render json: { error: "You need to login to use Cart" }, status: :forbidden
        end
    end
end
