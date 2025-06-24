class Api::V1::Customer::CartItemsController <  Api::V1::BaseController
    before_action :authorize_customer!

    def create
        @cart = @current_user.cart || @current_user.create_cart
        @cart_item = @cart.cart_items.find_or_initialize_by(product_id: params[:product_id])
        @cart_item.quantity = (@cart_item.quantity || 0) + params[:quantity].to_i
       
        if @cart_item.save
            render json: { message: "Item added to cart", cart_item: CartSerializer.new(@cart.reload).as_json }, status: :created
        else
            render json: { errors: @cart_item.errors.full_messages }, status: :unprocessable_entity
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
