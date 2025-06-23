class Api::V1::Public::ProductsController < ApplicationController
  def index
    @products = Product.page(params[:page]).per(params[:per_page] || 10)

    if @products.any?
      render json: {
        products: @products,
        meta: {
          current_page: @products.current_page,
          next_page: @products.next_page,
          prev_page: @products.prev_page,
          total_pages: @products.total_pages,
          total_count: @products.total_count
        }
      }, status: :ok
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
