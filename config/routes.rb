Rails.application.routes.draw do
  resources :favorites, only: %i[index create destroy]
  resource :cart, only: :show
  resources :cart_items, only: %i[create update destroy]
  resources :addresses
  resource :session
  resources :passwords, param: :token
  resources :categories , only: %i[index show]
  resources :orders, only: %i[index show new create] do  
    member do
      patch :cancel
    end
    resources :payments, only: :create
  end
  resource :profile, only: %i[show edit update]
  resource :password_change, only: %i[edit update]
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

    resources :products, only: %i[index show] do
      # Menambahkan route untuk membuat komentar pada produk
      resources :comments, only: :create
      resource :rating, only: %i[create update]
    end

    resource :registration, only: %i[new create]
    

  # Halaman admin: semua URL diawali /admin dan memakai controller di app/controllers/admin/
  namespace :admin do
    root "dashboard#show"
    resources :categories, except: :show  # menyediakan semua route kecuali show, karena admin tidak perlu melihat detail kategori
    resources :products, except: :show  # menyediakan semua route kecuali show, karena admin tidak perlu melihat detail produk
    resources :customers, only: %i[index show]
    resources :comments, only: :index do
      member do
        patch :hide
        patch :restore
      end
    end
    resources :orders, only: %i[index show] do
      member do # member block untuk menambahkan route yang memerluka n ID pesanan
        patch :ship
        patch :complete
        patch :cancel
      end
    end

    resources :payments, only: [] do
      member do
        patch :confirm
        patch :reject
      end
    end
  end


  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "home#index"
end
