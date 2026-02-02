Rails.application.routes.draw do
  # Admin namespace
  namespace :admin do
    root to: 'dashboard#index'

    get 'login', to: 'sessions#new'
    post 'login', to: 'sessions#create'
    delete 'logout', to: 'sessions#destroy'

    resource :settings, only: [:show, :update]
    resource :password, only: [:edit, :update]

    resources :customers do
      member do
        patch :toggle_status
      end
    end

    resources :categories do
      member do
        patch :toggle_status
      end
    end
    resources :products do
      resources :variants, controller: 'product_variants' do
        member do
          patch :toggle_status
          patch :update_stock
        end
      end
    end

    resources :orders do
      member do
        patch :confirm
        patch :process_order
        patch :ship
        patch :deliver
        patch :cancel
      end
      collection do
        get :drafts
      end
    end

    resources :draft_orders do
      member do
        post :convert_to_order
      end
    end

    resources :coupons do
      member do
        patch :toggle_status
      end
    end

    resources :reviews do
      member do
        patch :approve
        patch :reject
        patch :respond
      end
    end

    resources :support_tickets do
      resources :ticket_messages, only: [:create]
      member do
        patch :resolve
        patch :close
        patch :reopen
      end
    end

    resources :banners do
      member do
        patch :toggle_status
      end
    end

    # Inventory Management
    resources :inventory, only: [:index] do
      collection do
        get :adjustments
        get :bulk_adjust
        post :create_bulk_adjustment
        get :reorder_report
      end
      member do
        get :adjust
        post :create_adjustment
      end
    end

    get 'reports', to: 'reports#index'
    get 'reports/sales', to: 'reports#sales'
    get 'reports/products', to: 'reports#products'
    get 'reports/customers', to: 'reports#customers'
  end

  # Storefront (root namespace)
  root to: 'home#index'

  # Customer authentication
  get 'signup', to: 'registrations#new'
  post 'signup', to: 'registrations#create'
  get 'login', to: 'sessions#new'
  post 'login', to: 'sessions#create'
  delete 'logout', to: 'sessions#destroy'

  # Account
  resource :account, only: [:show, :edit, :update] do
    resource :password, only: [:edit, :update], controller: 'account_passwords'
  end

  # Products
  resources :products, only: [:index, :show], param: :slug
  resources :categories, only: [:show], param: :slug

  # Cart
  resource :cart, only: [:show] do
    post 'add/:variant_id', action: :add, as: :add_to
    patch 'update/:item_id', action: :update_item, as: :update_item
    delete 'remove/:item_id', action: :remove, as: :remove_from
    delete 'clear', action: :clear, as: :clear
    post 'apply_coupon', action: :apply_coupon, as: :apply_coupon
    delete 'remove_coupon', action: :remove_coupon, as: :remove_coupon
  end

  # Checkout
  resource :checkout, only: [:show, :create] do
    get 'address', action: :address
    post 'address', action: :save_address
    get 'confirm', action: :confirm
  end

  # Orders
  resources :orders, only: [:index, :show] do
    resources :reviews, only: [:new, :create], controller: 'order_reviews'
  end

  # Addresses
  resources :addresses

  # Support
  resources :support_tickets, path: 'support' do
    resources :messages, controller: 'customer_ticket_messages', only: [:create]
  end

  # Search
  get 'search', to: 'search#index'
  get 'search/suggestions', to: 'search#suggestions'

  # Health check
  get 'up' => 'rails/health#show', as: :rails_health_check
end
