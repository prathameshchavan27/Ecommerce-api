class Api::V1::Seller::ProductsController < Api::V1::BaseController
    before_action :authorize_seller!
    before_action :set_product, only: %i[update destroy]
    before_action :authorize_seller_owns_product!, only: %i[update destroy]

    def index
        @products = @current_user.products.all
        if @products.any?
            # render json: {products: @products}, status: :ok
            render json: {
                products: @products.as_json(
                    include: {
                        category: { # Include the associated category
                            only: [:id, :name] # Specify which attributes of category to include
                        }
                    }
                )
            }, status: :ok
        else
            render json: { errors: @products.errors.full_messages }, status: :unprocessable_entity
        end
    end

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

    def adjust_stock
        @product = @current_user.products.find_by(id: params[:id])
        if @product.nil?
            render json: {error: "Product not found or you don't have permimssion to adjust stock"}, status: :not_found
            return 
        end
        change_quantity = params[:change_quantity].to_i
        if change_quantity == 0
            render json: { error: "Change quantity must not be zero." }, status: :unprocessable_entity
            return
        end
        begin
            ActiveRecord::Base.transaction do
                if change_quantity > 0
                    @product.increase_stock(change_quantity)
                else
                    @product.decrease_stock(change_quantity.abs)
                end
            end
            render json: {
                message: "Product stock updated successfully.",
                product: @product.reload.as_json(only: [:id,:title,:stock])
            }, status: :ok
        rescue Product::InsufficientStockError => e
            render json: { error: e.message }, status: :unprocessable_entity
        rescue Product::ProductNotFoundError => e # Less likely here, but good for robustness
            render json: { error: e.message }, status: :forbidden
        rescue ArgumentError => e # Catches if quantity is not positive (as per product methods)
            render json: { error: "Invalid quantity: #{e.message}" }, status: :unprocessable_entity
        rescue StandardError => e
            Rails.logger.error "Error adjusting stock for product ID #{@product.id}: #{e.message}"
                render json: { error: "An unexpected error occurred while adjusting stock." }, status: :internal_server_error
        end
    end

    def destroy
        if @product.destroy
            render json: @product, status: :ok
        else
            render json: @product.errors.full_messages, status: :unprocessable_entity
        end
    end

    def bulk_stock_upload
        if params[:file].nil?
            render json: { error: "No file uploaded." }, status: :unprocessable_entity
            return
        end

        begin
            # Call the service object. On success, it returns the summary hash directly.
            # On failure, it will raise an exception.
            response_data = Product::BulkUpload.call(file: params[:file], current_user: @current_user)

            # If no exception was raised, the operation was successful.
            render json: response_data, status: :ok

        rescue => e # Catch any exception raised by the service object
            Rails.logger.error "Bulk stock upload failed: #{e.message}"
            # Render the error message directly from the caught exception
            render json: { error: e.message }, status: :unprocessable_entity 
        end
    end

    private

    def authorize_seller!
        Rails.logger.debug "💬 role = #{@current_user&.role.inspect}"
        unless @current_user&.role == :seller
            render json: { error: "Forbidden - Sellers only" }, status: :forbidden
        end
    end

    def set_product
        @product = Product.find(params[:id])
    end

    def authorize_seller_owns_product!
        unless @product.user.id == @current_user.id
            render json: { error: "Forbidden - Not your product" }, status: :forbidden
        end
    end

    def product_params
        params.require(:product).permit(:title, :description, :price, :stock, :category_id)
    end
end
