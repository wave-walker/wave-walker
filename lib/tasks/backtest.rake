# frozen_string_literal: true

namespace :backtest do
  desc 'Removes all backtest and initializes backtests.'
  task reset: :environment do
    Backtest.find_each do |backtest|
      asset_pair = backtest.asset_pair
      duration = backtest.duration

      ActiveRecord::Base.transaction do
        backtest.destroy!
        Backtest.create!(asset_pair:, duration:)
      end
    end
  end
end
