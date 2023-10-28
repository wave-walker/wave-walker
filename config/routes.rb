Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  resources :asset_pairs, only: [:index] do
    with_options module: 'asset_pairs' do
      resource :import, only: [:create]
    end
  end

  root "asset_pairs#index"
end
