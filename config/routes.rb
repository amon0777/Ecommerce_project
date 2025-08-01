Rails.application.routes.draw do
  # Devise and ActiveAdmin
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)

  # Root
  root "pages#home"

  # Editable static pages with fixed slugs
  get '/about', to: 'pages#show', defaults: { slug: 'about' }
  get '/contact', to: 'pages#show', defaults: { slug: 'contact' }

  # Products routes
  resources :products, only: [:index, :show] do
    collection do
      get :newly_added      # /products/newly_added
      get :recently_updated # /products/recently_updated
      get :on_sale          # /products/on_sale
    end
  end

  # Category-based products
  get 'categories/:id', to: 'categories#show', as: 'category'

  # Health check
  get "up", to: "rails/health#show", as: :rails_health_check

  # Fallback dynamic pages — restrict to known slugs only to avoid conflicts
  get '/:slug', to: 'pages#show', constraints: lambda { |req|
    %w[about contact].include?(req.params[:slug])
  }, as: :page
end
