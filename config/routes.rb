Rails.application.routes.draw do
  # Health check route
  get "up" => "rails/health#show", as: :rails_health_check

  devise_scope :user do
    namespace :api do
      namespace :v1 do
        post 'signup', to: 'registrations#create'   # POST /api/v1/signup
        post 'login', to: 'sessions#create'         # POST /api/v1/login
        delete 'logout', to: 'sessions#destroy'     # DELETE /api/v1/logout
      end
    end
  end
end
