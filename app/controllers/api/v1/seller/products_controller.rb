class Api::V1::Seller::ProductsController < Api::V1::BaseController
    before_action :authorize_seller!

    def create
        @product = @current_user.products.new(product_params)
        if @product.save
            render json: @product, status: :created
        else
            render json: { errors: @product.errors.full_messages }, status: :unprocessable_entity
        end
    end

    private

    def authorize_seller!
        Rails.logger.debug "💬 role = #{@current_user&.role.inspect}"
        unless @current_user&.role == :seller
            render json: { error: 'Forbidden - Sellers only' }, status: :forbidden
        end
    end

    def product_params
        params.require(:product).permit(:title, :description, :price, :stock, :category_id)
    end
end
