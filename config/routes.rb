Rails.application.routes.draw do
  root "chat_rooms#index"
  
  resources :chat_rooms, only: [:index, :show] do
    resources :messages, only: [:create]
  end
  
  get "login", to: "sessions#new"
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy"
  
  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end