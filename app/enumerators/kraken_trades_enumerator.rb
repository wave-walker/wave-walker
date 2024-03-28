# frozen_string_literal: true

class KrakenTradesEnumerator
  extend Limiter::Mixin

  def self.call(asset_pair, cursor:) = new(asset_pair, cursor:).to_enum(:each).lazy

  # Kraken allows 1 request per second. Allowing 55 requests ensures staying
  # staing under the rate limit.
  limit_method :load_trades, rate: 55, balanced: true

  def initialize(asset_pair, cursor:)
    @asset_pair = asset_pair
    @cursor = cursor.to_i
  end

  def each
    loop do
      trades = load_trades
      break if trades.empty?

      yield trades, cursor
    end
  end

  private

  attr_reader :asset_pair
  attr_accessor :cursor

  def load_trades
    response = Kraken.trades(pair: asset_pair.name, since: cursor)
    self.cursor = response.fetch(:last)

    response.fetch(:trades)
  end
end
