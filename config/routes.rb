Rails.application.routes.draw do
  root to: "dropers#index"

  namespace :embedded do
    resources :alerts
    root to: "alerts#index"
  end

  resources :bulk_products, only: [:index, :create]
  resources :dropers do
    collection do
      get "report"
      post "send_report"
      get "send_report_missing_products"
    end
  end
  resources :returns, only: [:new, :create]
  resources :sales do
    collection do
      get "report"
      get "import"
      post "import"
    end
  end
end
