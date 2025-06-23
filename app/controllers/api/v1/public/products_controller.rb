class Api::V1::Public::ProductsController < ApplicationController
   def index
    @products = Product.all

    if @products.any?
      render json: @products, status: :ok
    else
      render json: { message: 'No products found' }, status: :not_found
    end
  end

  def show
    @product = Product.find_by(id: params[:id])

    if @product
      render json: @product, status: :ok
    else
      render json: { error: 'Product not found' }, status: :not_found
    end
  end
end
