class Api::V1::Customer::OrdersController < Api::V1::BaseController
    before_action :authorize_customer!

    def create
        Orders::ProcessOrderJob.perform_later(@current_user.id)
        render json: { message: "Order is being processed!" }, status: :accepted
    end

    def authorize_customer!
        Rails.logger.debug "💬 role = #{@current_user&.role.inspect}"
        unless @current_user&.role == :customer
            render json: { error: 'You need to login to use Cart' }, status: :forbidden
        end
    end
end
