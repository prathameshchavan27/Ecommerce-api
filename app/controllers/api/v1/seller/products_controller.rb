class Api::V1::Seller::ProductsController < Api::V1::BaseController
    before_action :authorize_seller!
    before_action :set_product, only: %i[update destroy]
    before_action :authorize_seller_owns_product!, only: %i[update destroy]

    def create
        @product = @current_user.products.new(product_params)
        if @product.save
            render json: @product, status: :created
        else
            render json: { errors: @product.errors.full_messages }, status: :unprocessable_entity
        end
    end

    def update
        if @product.update(product_params)
            render json: @product, status: :ok
        else
            render json: { errors: @product.errors.full_messages }, status: :unprocessable_entity
        end
    end

    def destroy 
        @product.destroy
        render json: @product, status: :ok
    end

    private

    def authorize_seller!
        Rails.logger.debug "💬 role = #{@current_user&.role.inspect}"
        unless @current_user&.role == :seller
            render json: { error: 'Forbidden - Sellers only' }, status: :forbidden
        end
    end

    def set_product
        @product = Product.find(params[:id])
    end

    def authorize_seller_owns_product!
        unless @product.user.id == @current_user.id
            render json: { error: 'Forbidden - Not your product' }, status: :forbidden
        end
    end

    def product_params
        params.require(:product).permit(:title, :description, :price, :stock, :category_id)
    end
end
