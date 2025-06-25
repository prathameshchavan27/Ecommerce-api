class Api::V1::Customer::CartController < Api::V1::BaseController
    before_action :authorize_customer!

    private

    def authorize_customer!
        Rails.logger.debug "💬 role = #{@current_user&.role.inspect}"
        unless @current_user&.role == :customer
            render json: { error: 'You need to login to use Cart' }, status: :forbidden
        end
    end
end
