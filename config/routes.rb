Rails.application.routes.draw do
  # Admin namespace
  namespace :admin do
    root to: "dashboard#index"

    get "login", to: "sessions#new"
    post "login", to: "sessions#create"
    delete "logout", to: "sessions#destroy"

    resource :settings, only: [ :show, :update ]
    resource :store_settings, only: [ :show, :update ]
    resource :password, only: [ :edit, :update ]

    resources :customers do
      member do
        patch :toggle_status
      end
    end

    resources :categories do
      collection do
        patch :update_storefront_navbar
      end

      member do
        patch :toggle_status
      end
    end
    resources :products do
      collection do
        get :attribute_fields
      end
      member do
        post :generate_reviews
      end
      resources :variants, controller: "product_variants" do
        member do
          patch :toggle_status
          patch :update_stock
        end
      end
    end

    resources :orders, param: :order_number do
      member do
        patch :confirm
        patch :process_order
        patch :ship
        patch :deliver
        patch :cancel
        patch :rollback
        post :initiate_refund
        post :mark_refund_paid
        post :mark_refund_failed
        get :download_customer_invoice, defaults: { format: "pdf" }
        get :download_vendor_invoice, defaults: { format: "pdf" }
      end
      collection do
        get :drafts
        get :refunds
      end
    end

    resources :checkout_sessions, only: [ :index, :show ] do
      member do
        get :analytics
      end
    end

    resources :draft_orders, param: :order_number do
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

    resources :support_tickets, param: :ticket_number do
      resources :ticket_messages, only: [ :create ]
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

    resources :homepage_collections do
      member do
        patch :toggle_status
      end
      resources :homepage_collection_items, as: :items, path: :items
    end

    # Homepage Settings
    resource :homepage_settings, only: [ :show, :edit, :update ]

    # Inventory Management
    resources :inventory, only: [ :index ] do
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

    # Vendor management
    resources :vendors do
      member do
        patch :toggle_status
        post :act_as
        patch :reset_password
      end
    end
    delete "exit_vendor_mode", to: "vendors#exit_vendor_mode"

    # HSN Code management
    resources :hsn_codes do
      member do
        patch :toggle_status
      end
    end

    # Platform Fee Configuration
    resource :platform_fee_config, only: [ :show, :edit, :update ], path: :fee_settings

    # Vendor Earnings & Payouts (for vendors)
    get "earnings", to: "vendor_earnings#index", as: :vendor_earnings
    get "earnings/new_payout", to: "vendor_earnings#new_payout", as: :new_payout_vendor_earnings
    post "earnings/create_payout", to: "vendor_earnings#create_payout", as: :create_payout_vendor_earnings
    get "earnings/payouts", to: "vendor_earnings#payouts", as: :payouts_vendor_earnings
    get "earnings/payouts/:id", to: "vendor_earnings#show_payout", as: :show_payout_vendor_earnings

    # Admin Payout Management
    resources :payouts, only: [ :index, :show ] do
      member do
        patch :approve
        patch :reject
        patch :mark_paid
      end
    end

    get "reports", to: "reports#index"
    get "reports/sales", to: "reports#sales"
    get "reports/products", to: "reports#products"
    get "reports/customers", to: "reports#customers"
  end

  # Vendor authentication
  namespace :vendor, module: :vendor_portal do
    get "login", to: "sessions#new"
    post "login", to: "sessions#create"
    delete "logout", to: "sessions#destroy"
  end

  # Storefront (root namespace)
  root to: "home#index"

  # Customer authentication
  get "signup", to: "registrations#new"
  post "signup", to: "registrations#create"
  get "login", to: "sessions#new"
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy"

  # Account
  resource :account, only: [ :show, :edit, :update ] do
    resource :password, only: [ :edit, :update ], controller: "account_passwords"
  end

  # Products
  resources :products, only: [ :index, :show ], param: :slug

  # Categories redirect to products with category filter
  get "categories/:slug", to: "categories#show", as: :category

  # Cart
  resource :cart, only: [ :show ] do
    post "add/:variant_id", action: :add, as: :add_to
    patch "update/:variant_id", action: :update_item, as: :update_item
    delete "remove/:variant_id", action: :remove, as: :remove_from
    delete "clear", action: :clear, as: :clear
    post "apply_coupon", action: :apply_coupon, as: :apply_coupon
    delete "remove_coupon", action: :remove_coupon, as: :remove_coupon
    get "coupons", action: :coupons, as: :coupons
  end

  # Checkout
  resource :checkout, only: [ :show, :create ] do
    post "address", action: :save_address, as: :address
    get "confirm", action: :confirm
  end

  # Orders
  resources :orders, only: [ :index, :show ], param: :order_number do
    member do
      patch :cancel
      get :download_invoice, defaults: { format: "pdf" }
    end
    resources :reviews, only: [ :new, :create ], controller: "order_reviews"
  end

  # Unified Invoice Endpoint (accessible by customers, vendors, and admins)
  # GET /invoices/:order_number - Role-based invoice download
  resources :invoices, only: [ :show ], param: :order_number, defaults: { format: "pdf" }

  # Addresses
  resources :addresses, param: :token do
    member do
      patch :set_default
    end
  end

  # Wishlist
  resources :wishlists, only: [ :index, :create, :destroy ], param: :product_id do
    collection do
      delete :clear
    end
  end

  # Support
  resources :support_tickets, path: "support", param: :ticket_number do
    resources :messages, controller: "customer_ticket_messages", only: [ :create ]
  end

  # Search
  get "search", to: "search#index"
  get "search/suggestions", to: "search#suggestions"

  # PWA
  get "manifest.json", to: "pwa#manifest", defaults: { format: :json }
  get "service-worker.js", to: "pwa#service_worker", defaults: { format: :js }

  # Sitemap
  get "sitemap.xml", to: "sitemaps#show", defaults: { format: :xml }

  # Static Pages
  get "shipping", to: "pages#shipping"
  get "returns", to: "pages#returns"
  get "about", to: "pages#about"
  get "privacy", to: "pages#privacy"
  get "terms", to: "pages#terms"

  # Razorpay integration
  namespace :razorpay do
    post "webhook", to: "webhooks#handle"
    get "success", to: "callbacks#success"
    get "failure", to: "callbacks#failure"
  end

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
