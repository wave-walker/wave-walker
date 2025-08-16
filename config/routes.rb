# frozen_string_literal: true

Rails.application.routes.draw do
  get 'up' => 'rails/health#show', as: :rails_health_check

  resource :asset_pair_import, only: %i[new create destroy]
  resources :asset_pairs, only: %i[index show] do
    resources :durations, only: [] do
      resources :chart_ticks, only: %i[index], defaults: { format: :json }
    end
  end
  resources :backtests, only: %i[index show]
  resources :reset_backtests, only: :create

  root 'dashboards#show'

  mount MissionControl::Jobs::Engine, at: '/jobs'
end
