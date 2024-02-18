# frozen_string_literal: true

Rails.application.routes.draw do
  get 'up' => 'rails/health#show', as: :rails_health_check

  resources :asset_pairs, only: [:index] do
    with_options module: 'asset_pairs' do
      resource :import, only: [:create]
      resources :ohlcs, only: [:index]
    end
  end

  root 'asset_pairs#index'

  mount GoodJob::Engine => 'good_job'
end
