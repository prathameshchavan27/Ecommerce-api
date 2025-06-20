
# require 'warden/jwt_auth'

# module Api
#   module V1
#     class BaseController < ActionController::API
#       respond_to :json

#       before_action :authenticate_user_from_token!
#       before_action :log_current_user

#       attr_reader :current_user
# before_action :set_current_user

# def set_current_user
#   @current_user = current_api_v1_user
# end
#       private

#       def authenticate_user_from_token!
#         token = request.headers['Authorization']&.split(' ')&.last
#         if token
#           begin
#             payload = Warden::JWTAuth::TokenDecoder.new.call(token)
#             @current_user = User.find(payload['sub'])
#           rescue JWT::ExpiredSignature
#             render json: { error: 'Token has expired' }, status: :unauthorized
#           rescue => e
#             Rails.logger.error "JWT Decode Error: #{e.message}"
#             render json: { error: 'Invalid token' }, status: :unauthorized
#           end
#         else
#           render json: { error: 'Missing token' }, status: :unauthorized
#         end
#       end

#       def log_current_user
#         Rails.logger.debug "🔐 Authorization: #{request.headers['Authorization']}"
#         Rails.logger.debug "👤 Current User: #{@current_user.inspect}"
#       end
#     end
#   end
# end

require 'warden/jwt_auth'

module Api
  module V1
    class BaseController < ActionController::API
      respond_to :json

      before_action :authenticate_user_from_token!
      before_action :log_current_user

      attr_reader :current_user

      private

      def authenticate_user_from_token!
        token = request.headers['Authorization']&.split(' ')&.last
        if token
          begin
            payload = Warden::JWTAuth::TokenDecoder.new.call(token)
            @current_user = User.find_by(id: payload['sub'])

            unless @current_user
              render json: { error: 'User not found' }, status: :unauthorized
            end
          rescue JWT::ExpiredSignature
            render json: { error: 'Token has expired' }, status: :unauthorized
          rescue => e
            Rails.logger.error "JWT Decode Error: #{e.message}"
            render json: { error: 'Invalid token' }, status: :unauthorized
          end
        else
          render json: { error: 'Missing token' }, status: :unauthorized
        end
      end

      def log_current_user
        Rails.logger.debug "🔐 Authorization: #{request.headers['Authorization']}"
        Rails.logger.debug "👤 Current User: #{@current_user.inspect}"
      end
    end
  end
end
