# frozen_string_literal: true

Rails.application.routes.draw do
  get 'up' => 'rails/health#show', as: :rails_health_check

  resource :asset_pair_import, only: %i[new create]
  resources :asset_pairs, only: %i[index show]
  resources :backtests, only: %i[index]

  root 'dashboards#show'

  mount GoodJob::Engine => 'good_job'
end
