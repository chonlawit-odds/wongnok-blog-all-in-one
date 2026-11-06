Rails.application.routes.draw do
  # login ด้วย Keycloak: POST /auth/keycloak ถูก OmniAuth middleware รับไปก่อนถึง routes (ไม่ต้องประกาศ)
  resource :session, only: %i[ new destroy ]
  get "auth/keycloak/callback", to: "sessions#create", as: :keycloak_callback
  get "auth/failure", to: "sessions#failure", as: :auth_failure

  resources :posts do
    resources :comments, only: %i[ create destroy ]
    # ปุ่ม "เผยแพร่ทันที": POST /posts/:post_id/publication -> Posts::PublicationsController#create
    resource :publication, only: :create, module: :posts
  end
  resources :followers, only: %i[ new create ]
  resources :categories
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
