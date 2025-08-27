Rails.application.routes.draw do
  # Health checks
  get "up" => "rails/health#show", as: :rails_health_check
  get "health" => "health#show", as: :health_check

  # Root route
  root 'home#index'

  # Luigi sessions
  resources :sessions, only: [:show, :create, :index] do
    member do
      get :export
    end
    
    # Nested messages
    resources :messages, only: [:create]
    
    # Audio transcription
    post :transcribe, to: 'audio#transcribe'
  end

  # Direct audio upload route
  resources :audio, only: [] do
    collection do
      post :transcribe
    end
  end

  # Knowledge graph API endpoints
  namespace :api do
    namespace :v1 do
      resources :knowledge_graph, only: [:show] do
        collection do
          get :stats
          get :entities
          get :relationships
        end
      end
    end
  end

  # Sidekiq web interface (development/staging only)
  if Rails.env.development? || Rails.env.staging?
    require 'sidekiq/web'
    mount Sidekiq::Web => '/sidekiq'
  end

  # Action Cable
  mount ActionCable.server => '/cable'
end