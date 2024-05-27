# frozen_string_literal: true

Rails.application.routes.draw do
  get 'up' => 'rails/health#show', as: :rails_health_check

  resource :asset_pair_import, only: %i[new create]
  resources :asset_pairs, only: %i[index show] do
    resources :durations, only: [] do
      resources :chart_ticks, only: %i[index], defaults: { format: :json }
    end
  end
  resources :backtests, only: %i[index]

  root 'dashboards#show'

  mount GoodJob::Engine => 'good_job'
end
