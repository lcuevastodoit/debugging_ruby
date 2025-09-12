Rails.application.routes.draw do
  resources :debugging_game, only: [:index] do
    collection do
      post :reset
      post :start_monitoring
      post :stop_monitoring
      get :objective, to: 'debugging_game#show'
      get :live_status
      post :get_hint
    end
  end
  
  root 'debugging_game#index'

  resources :users do
    resources :posts
  end

  resources :users, only: [:index, :show, :new, :create]

  get 'debug_error', to: 'users#index', defaults: { debug: 'error' }

  get "up" => "rails/health#show", as: :rails_health_check
end
