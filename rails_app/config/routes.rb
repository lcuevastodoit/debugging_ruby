Rails.application.routes.draw do
  resources :debugging_game, only: [:index] do
    collection do
      post :reset
      post :start_monitoring
      post :stop_monitoring
      get :objective, to: 'debugging_game#show'
      get :live_status
      post :get_hint
      post :test_job
    end
  end

  root 'debugging_game#index'

  resources :users do
    resources :posts
  end

  resources :users, only: [:index, :show, :new, :create]

  get 'debug_error', to: 'users#index', defaults: { debug: 'error' }

  # Mission Control Jobs web interface
  mount MissionControl::Jobs::Engine, at: "/jobs"

  get "up" => "rails/health#show", as: :rails_health_check
end
