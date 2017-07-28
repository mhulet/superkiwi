Rails.application.routes.draw do
  root to: "dropers#index"

  resources :returns, only: [:new, :create]

  resources :sales do
    collection do
      get "report"
      get "import"
      post "import"
    end
  end

  resources :dropers do
    collection do
      get "report"
      post "send_report"
      get "send_report_missing_products"
    end
  end
end
