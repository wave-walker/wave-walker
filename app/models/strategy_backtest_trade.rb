# frozen_string_literal: true

class StrategyBacktestTrade < ApplicationRecord
  include DurationConcern
  include RangeConcern

  self.primary_key = %i[strategy_id asset_pair_id iso8601_duration range_position]

  belongs_to :strategy_backtest,
             foreign_key: %i[strategy_id asset_pair_id iso8601_duration],
             inverse_of: :strategy_backtest_trades
  belongs_to :ohlc,
             foreign_key: %i[asset_pair_id iso8601_duration range_position],
             inverse_of: false

  enum :action, { buy: 'buy', sell: 'sell' }

  def value = price * volume
end
