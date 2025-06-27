class Api::V1::Customer::CartItemsController <  Api::V1::BaseController
    before_action :authorize_customer!

    def create
        @cart = @current_user.cart || @current_user.create_cart

        service = CartItems::AddItemToCart.new(@cart, params[:product_id], params[:quantity])
        cart_item = service.call

        if cart_item.persisted?
            render json: { message: "Item added to cart", cart_item: CartSerializer.new(@cart).as_json }, status: :created
        else
            render json: { errors: cart_item.errors.full_messages }, status: :unprocessable_entity
        end
    end

    def update
        @cart = @current_user.cart || @current_user.create_cart
        service = CartItems::UpdateCartItems.new(@cart, params[:id], params[:quantity])
        cart_item = service.call

        if cart_item.errors.empty?
            render json: { message: "Item Updated in cart", cart_item: cart_item }, status: :ok
        else
            render json: { errors: cart_item.errors.full_messages }, status: :unprocessable_entity
        end
    end

    def destroy
        @cart = @current_user.cart || @current_user.create_cart
        service = CartItems::DeleteCartItems.new(@cart, params[:id])
        cart_item = service.call

        if cart_item.errors.empty?
            render json: { message: "Item removed from cart", cart_item: cart_item }, status: :ok
        else
            render json: { errors: cart_item.errors.full_messages }, status: :unprocessable_entity
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
