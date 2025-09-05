class Api::V1::Users::ProfilesController < Api::V1::BaseController
    before_action :authorize_user!

    def show
        render json: {
            user: current_user.as_json(
                include: {
                    orders: {
                        only: [ :id, :total_price, :status, :created_at ]
                    }
                }
            )
        }
    end

    def update
        if current_user.update(profile_params)
        render json: current_user
        else
        render json: { errors: current_user.errors.full_messages }, status: :unprocessable_entity
        end
    end

    private

    def profile_params
        params.permit(:name)
    end

    def authorize_user!
        Rails.logger.debug "💬 role = #{@current_user&.role.inspect}"
        unless @current_user&.role == :customer || @current_user&.role == :admin || @current_user&.role == :seller
            render json: { error: "You need to login to use Cart" }, status: :forbidden
        end
    end
end
