# frozen_string_literal: true

class BacktestTrade < ApplicationRecord
  include DurationConcern
  include RangeConcern

  belongs_to :backtest, foreign_key: %i[asset_pair_id iso8601_duration],
                        inverse_of: :backtest_trades
  belongs_to :ohlc, foreign_key: %i[asset_pair_id iso8601_duration range_position],
                    inverse_of: :backtest_trade

  enum :action, { buy: 'buy', sell: 'sell' }

  def value = price * volume
end
