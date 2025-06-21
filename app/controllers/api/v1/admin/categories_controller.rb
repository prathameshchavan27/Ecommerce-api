
# module Api
#   module V1
#     module Admin
#       class CategoriesController < Api::V1::BaseController
#         before_action :authenticate_api_v1_user!
#         before_action :authorize_admin!, only: [:create]

#         def create
#           category = Category.new(category_params)
#           if category.save
#             render json: category, status: :created
#           else
#             render json: { errors: category.errors.full_messages }, status: :unprocessable_entity
#           end
#         end

#         private

#         def category_params
#           params.require(:category).permit(:name, :description)
#         end

#         # def authorize_admin!
#         #     unless current_user&.role == 'admin'
#         #         render json: { error: 'Forbidden - Admins only' }, status: :forbidden
#         #     end
#         # end
#         def authorize_admin!
#             Rails.logger.debug "💬 role = #{@current_user&.roles.inspect}"
#             unless @current_user&.roles == 'admin'
#                 render json: { error: 'Forbidden - Admins only' }, status: :forbidden
#             end
#         end


#         def debug_current_user
#             Rails.logger.info "🔍 current_user: #{current_api_v1_user.inspect}"
#             Rails.logger.info "🔐 JWT header: #{request.headers['Authorization']}"
#         end
#       end
#     end
#   end
# end
module Api
  module V1
    module Admin
      class CategoriesController < Api::V1::BaseController
        before_action :authorize_admin!
        before_action :set_category, only: %i[update destroy]
        def create
          category = Category.new(category_params)
          if category.save
            render json: category, status: :created
          else
            render json: { errors: category.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def update
            if @category.update(category_params)
                render json: @category, status: :ok
            else
                render json: { errors: @category.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def destroy
            if @category.destroy
                render json: @category, status: :ok
            else
                render json: { errors: @category.errors.full_messages }, status: :unprocessable_entity
            end
        end

        private

        def category_params
          params.require(:category).permit(:name, :description)
        end

        def set_category
            @category = Category.find(params[:id])
        end

        def authorize_admin!
          Rails.logger.debug "💬 role = #{@current_user&.role.inspect}"
          unless @current_user&.role == :admin
            render json: { error: 'Forbidden - Admins only' }, status: :forbidden
          end
        end

        def debug_current_user
          Rails.logger.info "🔍 current_user: #{@current_user.inspect}"
          Rails.logger.info "🔐 JWT header: #{request.headers['Authorization']}"
        end
      end
    end
  end
end


