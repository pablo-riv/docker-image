require 'api_constraints'

Rails.application.routes.draw do
  get '/ping', action: :index, controller: 'pings'
  namespace :admin do
    get 'users/index'
  end

  namespace :admin do
    get 'users/show'
  end

  root 'public#dashboard'
  post 'public#enable_suite', to: 'public#enable_suite', as: :enable_suite
  get 'dashboard', to: 'public#dashboard'
  get 'instructions', to: 'public#instructions'
  post 'deliveries', to: 'public#deliveries'
  post 'fulfillment_request', to: 'public#fulfillment_request'

  devise_for :accounts, controllers: {
    registrations: 'accounts/registrations',
    sessions: 'accounts/sessions',
    passwords: 'accounts/passwords'
  }

  namespace :setup do
    get :company, to: 'companies#edit'
    patch :company, to: 'companies#update'
    resources :branch_offices, only: [:edit, :update]
    resources :people, only: [:edit, :update]
    resources :services, only: [] do
      resources :settings, only: [:edit, :update]
    end
  end

  resources :debtors, only: %i[index]
  resources :negotiations, only: %i[] do
    get 'company', action: 'show', on: :collection
  end
  resources :budgets, only: %i[index] do
    collection do
      get 'v2', action: 'v2'
    end
  end
  resources :notifications, only: %i[index show] do
    collection do
      get 'by_company', action: 'by_company'
      put 'single_update', action: 'update'
    end
  end

  resources :mail_notifications, only: %i[show update] do
    get ':state/edit', action: 'edit', on: :collection, as: 'edit'
    post ':id/test', action: 'test', on: :collection, as: 'test'
  end

  resources :helps, only: %i[index create show] do
    collection do
      get  'supports', action: :supports
      post 'syncronize', action: :syncronize
    end
  end

  resources :companies, only: %i[edit update] do
    collection do
      get 'query', to: 'companies#query'
      put 'update_preference'
    end
    # resources :accounts, only: %i[create] # move to accounts path (without company) -> check POST /accounts of Devise
  end

  resources :branch_offices, only: [:index, :new, :create, :edit, :update, :destroy] do
    collection do
      post 'marketplace_request', action: 'marketplace_request'
      get ':company_id/all', action: 'all'
      get 'communes', action: 'communes'
    end
    resources :accounts, only: [:index, :new, :create, :edit, :update, :destroy]
  end

  resources :accounts, only: [:index, :new, :edit, :update]
  resources :packages, only: [:index, :show, :new, :create, :edit, :destroy, :update, :return] do
    collection do
      post 'bootic_integration', action: 'bootic_integration'
      get  'find_sku/:id',       action: 'find_sku'
      get  'filter_communes',    action: 'filter_communes'
      get 'massive', action: 'massive'
      post 'massive_packages', action: 'massive_packages_create'
      post 'download', action: 'download'
      get 'find', action: 'find'
      get 'monitor', action: 'monitor'
      post 'by_references', action: 'by_references'
    end
  end

  namespace :returns do
    resources :packages, only: %i[index create] do
      collection do
        get 'new/:id', action: 'new', as: 'new'
        get 'search', action: 'search', as: 'search'
        get 'operation', action: 'operation', as: 'operation'
        post 'to_client', action: 'to_client', as: 'to_client'
      end
    end
  end

  resources :services, only: [:index] do
    post 'assign', action: 'assign'
    resources :settings, only: [:index, :edit, :update, :destroy] do
      post 'import', action: 'import'
      get 'prices', action: 'prices'
      get 'couriers', action: 'couriers'
      patch 'update_integrations', action: 'update_integrations'
    end
  end

  resources :analytics, only: [:index] do
    collection do
      get 'search', action: :search_by_date
    end
  end

  resources :settings, only: [:index, :current] do
    collection do
      get 'current', action: 'current', as: :current
      get 'api', action: 'api', as: 'api'
      put 'webhooks', action: 'webhooks', as: 'webhooks'
      get 'my_integrations', to: 'settings#my_integrations'
      get 'fullit_setting', to: 'settings#fullit_setting'
      get 'sellers_integrated', to: 'settings#sellers_integrated'
      get 'oauth_bridge', action: 'oauth_bridge'
      get 'bootic_callback', action: 'bootic_callback'
      get 'config_couriers'
      get 'config_printers'
    end
  end

  resources :integrations, only: [:index] do
    collection do
      get 'integration_orders', to: 'integrations#integration_orders'
      get 'is_downloading', to: 'integrations#is_downloading'
      get 'download', action: 'download'
      post 'push_orders', as: 'push_orders'
      get 'download_csv', as: 'download_csv'
      get 'download_plugin', action: 'download_plugin'
      get 'download_pdf', action: 'download_pdf'
      get 'faq', action: 'faq'
      post 'archive', to: 'integrations#archive'
      patch ':id/update_order', to: 'integrations#update_order'
      post 'by_refereneces', action: :by_refereneces
    end
  end

  resources :labels, only: [:index, :create] do
    collection do
      get 'today', action: :today
      get 'search', action: :search
      get 'pack', action: :pack
      get 'daily_printed', action: :daily_printed
      get 'by_reference', action: :by_reference
    end
  end

  # people don't forget
  resources :charges, only: [:index] do
    collection do
      get 'fullfilment', to: 'charges#fullfilment'
      get 'fullfilment/year/:year/month/:month', to: 'charges#fullfilment_by_month', as: 'fullfilment_by_month'
      # get 'fullfilment/year/:year/month/:month/details', to: 'charges#fullfilment_by_month_details', as: 'fullfilment_by_month_details'

      get 'fulfillment/year/:year/xls', action: 'fulfillment_xls', as: 'fulfillment_year_xls'
      get 'fulfillment/year/:year/month/:month/xls', action: 'fulfillment_xls', as: 'fulfillment_month_xls'

      get 'fulfillment/year/:year/month/:month/packages', action: 'fulfillment_month_packages', as: 'fulfillment_month_packages'
      get 'fulfillment/year/:year/month/:month/day/:day/packages', action: 'fulfillment_day_packages', as: 'fulfillment_day_packages'

      get 'fulfillment/year/:year/month/:month/packages/xls', action: 'fulfillment_packages_xls', as: 'fulfillment_month_packages_xls'
      get 'fulfillment/year/:year/month/:month/day/:day/packages/xls', action: 'fulfillment_packages_xls', as: 'fulfillment_day_packages_xls'


      get 'pickandpack'
      get 'pickandpack/year/:year/month/:month', to: 'charges#pickandpack_by_month', as: 'pickandpack_by_month'
      get 'pickandpack/year/:year/month/:month/csv', to: 'charges#pickandpack_by_month_csv', as: 'pickandpack_by_month_csv'
      get 'pickandpack/year/:year/month/:month/extras', to: 'charges#pickandpack_extras_by_month', as: 'pickandpack_extras_by_month'
      get 'fines'
      get 'parking'
      get 'discounts'
    end
  end

  resources :couriers_branch_offices, only: [:index]

  namespace :v, defaults: { format: :json } do
    devise_scope :account do
      post 'sign_up', to: 'registrations#create', as: 'sign_up'
      post 'login', to: 'sessions#create', as: 'login'
      delete 'logout', to: 'sessions#destroy', as: 'logout'
      get 'reset_password', to: 'passwords#new', as: 'reset_password'
      post 'passwords', to: 'passwords#create'
    end

    post '/zendesk/sync_tickets', action: :create, as: :create, to: 'zendesk#create'

    scope module: :v1, constraints: APIConstraints.new(version: 1) do
      resources :packages do
        collection do
          post 'mass_create'
        end
      end
    end
    scope module: :v2, constraints: APIConstraints.new(version: 2, default: true) do
      get 'ticks/tacks'
      resources :trackings, only: [] do
        get '/:number', on: :collection, action: :show
      end
      resources :couriers, only: [:index]
      resources :regions, only: [:index, :show]
      resources :communes, only: [:index, :show, :by_commune, :availible_commune_starken] do
        get 'by_name/:name', action: 'by_name', on: :collection
        get '/availible_commune_starken', action: 'availible_commune_starken', on: :collection
      end
      resources :skus do
        collection do
          get 'by_client', action: 'by_client'
          get 'by_name', action: 'by_name'
          post 'new_series_out', action: 'new_series_out'
        end
      end
      resources :packages, only: %i[index show create update]  do
        collection do
          post 'mass_create'
          post 'integration'
          post 'backup'
          get 'reference/:reference', action: 'package_by_reference'
          get 'filter', action: 'filter'
        end
      end

      resources :shippings, only: [:cost, :costs, :price, :prices] do
        collection do
          post 'price'
          post 'prices'
          post 'prices_v2'
          post 'cost'
        end
      end

      resources :labels, only: [:create]
      resources :orders, only: [:create] do
        collection do
          post 'order_received'
          post 'massive'
          post '/bsale', action: 'create'
          put '/bsale', action: 'create'
        end
      end
      resources :webhooks, only: [] do
        collection do
          patch 'package', action: 'update'
          get 'package', action: 'show'
        end
      end

      resources :zendesk, only: %i[sync_tickets submit_message] do
        collection do
          post 'sync_tickets'
          post 'submit_message'
        end
      end

      resources :settings, only: [:index, :update]

      resources :branch_offices, only: [:index, :show, :create]
    end
    scope module: :v3, constraints: APIConstraints.new(version: 3) do
      resource :prices, only: [:create], controller: :calculator
      resources :printers, only: [:create] do
        post 'massive', on: :collection
      end
      resources :communes, only: [:index, :show, :by_commune] do
        get 'by_name/:name', action: 'by_name', on: :collection
      end
    end

    scope module: :v4, constraints: APIConstraints.new(version: 4) do
      resources :helps, only: %i[index create show] do
        collection do
          get  'supports', action: :supports
          post 'syncronize', action: :syncronize
        end
      end
      resources :downloads, only: %i[index show destroy]
      resources :suite_notifications, only: %i[index show destroy]
      resources :pickups, only: %i[index show create]
      resources :charges, only: %i[index] do
        collection do
          get '/:year/:month', action: :show
          post '/:kind/download', action: :download
          get '/details', action: :details
          post '/download_shipments/by_date', action: :download_shipments_by_date
        end
      end
      resources :companies, only: %i[index]
      resources :accounts, only: %i[index] do
        get '/information', action: 'show', on: :collection
        post '/disable_suite', action: 'disable_suite', on: :collection
      end
      resources :labels, only: [] do
        get '/information', action: 'show', on: :collection
        patch '', action: 'update', on: :collection
      end
      resources :setup, only: [] do
        collection do
          get '/administrative', action: :show
          patch '/administrative', action: :administrative
          patch '/operative', action: :operative
          patch '/account', action: :account
        end
      end
      resources :shipments do
        collection do
          post 'massive', action: :massive
          post '/massive/import', action: :massive_import
          get '/download', action: :download
          get '/counter', action: :counter
          get '/monthly', action: :monthly
          get '/check_reference', action: :check_reference
          patch '/dispatch_date', action: :dispatch_date
          delete '/massive_archive', action: :massive_archive
          get '/reference/:reference', action: 'by_reference'
        end
      end

      resources :orders, only: %i[index]

      resources :printers, only: %i[index show create] do
        collection do
          get 'references', action: :references
        end
      end
      resources :calendars, only: %i[index]
      resources :products
      resources :salesmen, only: %i[] do
        collection do
          get 'company', action: :show
        end
      end
      resources :partners, only: %i[index show] do
        get '/:ref', action: :show, on: :collection
      end
      resources :packings
      resources :origins
      resources :destinies
      resources :address_books
      resources :insurances
      resources :subscriptions, only: [:show, :create, :update] do
        collection do
          patch '/activate' , action: :activate
          patch '/change_plan' , action: :change_plan
        end
      end
      resources :apps_collections, only: [:create]
      resources :couriers, only: %i[index show] do
        get '/algorithm', action: :algorithm, on: :collection
        patch '/algorithm', action: :update_algorithm, on: :collection
        get 'branch_offices', action: :branch_offices, on: :member
        patch '/:name', action: :update, on: :collection
        get 'availables', action: :availables, on: :collection
      end

      resources :plans, only: [:index]
      resources :settings, only: [:index] do
        collection do
          get '/:service_id', action: :show
          patch '/automatizations/:id', action: :automatizations
        end
      end

      resources :notifications, only: [] do
        collection do
          get '/setting', action: :setting, as: 'setting'
          get '/preference', action: :preference, as: 'preference'
          get '/:state', action: :show, as: 'show'
          patch '/active/:id', action: :active, as: 'active'
          patch '/:state', action: :update, as: 'update'
          patch '/preference/:comany_id', action: :update_preference, as: 'update_preference'
          post '/:state/test', action: :test, as: 'test'
        end
      end

      resources :whatsapps, only: [] do
        collection do
          get '/setting', action: :setting, as: 'setting'
          get '/:state', action: :show, as: 'show'
          patch '/:state/active/:id', action: :active
          patch '/:state', action: :update, as: 'update'
          post '/:state/test', action: :test, as: 'test'
        end
      end

      namespace :fulfillment do
        resources :skus, only: %i[index show] do
          collection do
            get 'all', as: :all, action: :all
            put 'update_min_stock', action: :update_min_stock, as: :update_min_stock
            get 'by_name', action: :by_name
            get 'download', as: :download, action: :download
          end
        end
        resources :inventories, only: %i[index show] do
          collection do
            get 'download', as: :download, action: :download
          end
        end
        resources :warehouses, only: %i[index]
      end
      resources :searchs, only: %i[index]

      namespace :returns do
        resources :shipments, only: %i[index show] do
          collection do
            post 'client', action: :client
            post 'buyer', action: :buyer
            get '/counter', action: :counter
            get '/factoring', action: :factoring
          end
        end
      end

      namespace :setups do
        resources :commercial, only: %i[show create update]
        resources :administrative, only: %i[show create update]
        resources :operative, only: %i[show create update]
        resources :plans, only: [:index]
        resources :drop_outs, only: %i[index] do
          collection do
            patch '/deactivate', action: :deactivate
            patch '/reactivate', action: :reactivate
          end
        end
        resources :subscriptions, only: [:show, :create, :update] do
          collection do
            patch '/activate' , action: :activate
            patch '/change_plan' , action: :change_plan
          end
        end
      end

      resources :communes, only: %i[index show by_commune] do
        get 'by_name/:name', action: 'by_name', on: :collection
      end
      resources :rates, only: %i[create]
      resources :prices, only: %i[create], controller: :calculator do
        collection do
          post 'massive', action: :massive
          post 'quotations', action: :quotations
        end
      end
      resources :integrations, only: %i[index] do
        collection do
          get '/configuration', action: :configuration
          patch 'setting', action: :setting
          patch 'webhook', action: :webhook
          get '/seller/:name', action: :show
        end
      end
      resources :couriers, only: %i[index show] do
        get '/algorithm', action: :algorithm, on: :collection
        patch '/algorithm', action: :update_algorithm, on: :collection
        get 'branch_offices', action: 'branch_offices', on: :member
        patch '/:name', action: :update, on: :collection
        get 'availables', action: :availables, on: :collection
      end

      resources :analytics, only: %i[index] do
        collection do
          get '/operational', action: 'operational'
          get '/pickups', action: 'pickups'
          get '/:model/charts', action: 'charts'
        end
      end
      namespace :tickets do
        resources :zendesk, only: %i[submit_message] do
          collection do
            post "submit_message"
          end
        end
      end

      get :courier_destinies, to: 'courier_destinies#availability'
    end
  end

  resources :fulfillment, only: [] do
    collection do
      get 'inventory', action: :inventory
      get 'receipt', action: :receipt
      get 'out', action: :out
      get 'history', action: :history
    end
  end

  resources :skus, only: [:show] do
    collection do
      get 'by_client', action: :by_client
      post 'update_min_stock', action: :update_min_stock
    end
  end
  resources :ff_activity, only: [:show]


  namespace :headquarter do
    get 'dashboard', to: 'public#dashboard'
    get 'instructions', to: 'public#instructions'
    resources :debtors, only: %i[index]
    resources :packages, only: [:index, :show, :new, :create] do
      get 'by_branch_office', on: :collection
    end
  end

  resources :products
  resources :packings

  match '*path', to: 'public#catch_404', via: :all
  mount ActionCable.server => '/cable'
end
