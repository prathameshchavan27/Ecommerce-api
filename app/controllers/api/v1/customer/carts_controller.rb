class Api::V1::Customer::CartsController < Api::V1::BaseController
    before_action :authorize_customer!

    def show
        @cart = @current_user.cart || @current_user.create_cart
        puts @cart.cart_items
        if @cart.cart_items
            render json: {cart: CartSerializer.new(@cart).as_json}, status: :ok
        else
            render json: {message: "No items found in cart"}, status: :unprocessable_entity
        end
    end

    private

    def authorize_customer!
        Rails.logger.debug "💬 role = #{@current_user&.role.inspect}"
        unless @current_user&.role == :customer
            render json: { error: 'You need to login to use Cart' }, status: :forbidden
        end
    end
end
