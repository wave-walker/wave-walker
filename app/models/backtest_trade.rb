# frozen_string_literal: true

class BacktestTrade < ApplicationRecord
  include DurationConcern
  include RangeConcern

  belongs_to :backtest, query_constraints: %i[asset_pair_id iso8601_duration]
  belongs_to :ohlc, query_constraints: %i[asset_pair_id iso8601_duration range_position]

  enum trade_type: { buy: 'buy', sell: 'sell' }

  def value = (price * quantity) - fee
end
