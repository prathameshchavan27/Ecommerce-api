Rails.application.routes.draw do
  require "sidekiq/web"
  mount Sidekiq::Web => "/sidekiq"

  namespace :api do
    namespace :v1 do
      devise_for :users,
        path: "",
        path_names: {
          sign_in: "login",
          sign_out: "logout",
          registration: "register"
        },
        controllers: {
          sessions: "api/v1/users/sessions",
          registrations: "api/v1/users/registrations"
        }
        namespace :admin do
          resources :categories
        end

        namespace :seller do
          resources :products, only: [:create, :update, :destroy] do
            member do
              patch :adjust_stock
            end
          end
        end

        namespace :public do
          resources :products, only: [ :index, :show ]
        end

        namespace :customer do
          resource :cart, only: [ :show ] do
            delete :clear, on: :collection
          end
          resources :cart_items, only: [ :create, :update, :destroy ]

          resources :orders, only: [ :create, :index, :show ] do
            member do
              post :cancel
            end
            collection do
              post :direct_checkout
            end
          end
        end
    end
  end
end
