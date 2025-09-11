Rails.application.routes.draw do
  root 'users#index'

  resources :users do
    resources :posts
  end

  get 'debug_error', to: 'users#index', defaults: { debug: 'error' }

  get "up" => "rails/health#show", as: :rails_health_check
end
