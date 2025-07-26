class Api::V1::Public::CategoriesController < ApplicationController
    def index
        @categories = Category.all;
        if @categories.any?
            render json:  @categories, status: :ok
        else
            render json: { errors: @categories.errors.full_messages }, status: :unprocessable_entity
        end
    end

    def show 
        @category = Category.find(params[:id])
        if @category
            render json: @category, status: :ok
        else
            render json: { errors: @category.errors.full_messages }, status: :unprocessable_entity
        end
    end
end