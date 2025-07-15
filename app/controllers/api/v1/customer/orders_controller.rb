class Api::V1::Customer::OrdersController < Api::V1::BaseController
    before_action :authorize_customer!

    def create
        Orders::ProcessOrderJob.perform_later(@current_user.id)
        render json: { message: "Order is being processed!" }, status: :accepted
    end

    def direct_checkout
        requested_quantity = params[:quantity].to_i
        product = Product.where(id: params[:product_id])
                        .where("stock >= ?", requested_quantity)
                        .first

        if product.nil?
            render json: { error: "Product out of stock" }, status: :ok
            return
        end

        ActiveRecord::Base.transaction do
            @order = @current_user.orders.create!(
                total_price: product.price.to_i * requested_quantity,
                status: :placed
            )

            @order.order_items.create!(
                product: product,
                quantity: requested_quantity,
                price: product.price
            )
            product.decrease_stock(requested_quantity)
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
