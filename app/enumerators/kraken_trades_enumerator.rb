# frozen_string_literal: true

class KrakenTradesEnumerator
  extend Limiter::Mixin

  def self.call(asset_pair, cursor:) = new(asset_pair, cursor:).to_enum(:each).lazy

  # Kraken allows 1 request per second. Allowing 50 requests ensures staying
  # staying under the rate limit.
  limit_method :load_trades, rate: 50, balanced: true

  def initialize(asset_pair, cursor:)
    @asset_pair = asset_pair
    @cursor = cursor
  end

  def each
    loop do
      trades = load_trades
      break if trades.empty?

      yield({ asset_pair:, trades: }, cursor)
    end
  end

  private

  attr_reader :asset_pair
  attr_writer :cursor

  def cursor
    @cursor ||= asset_pair.trades.last&.created_at.to_i
  end

  def load_trades
    response = Kraken.trades(pair: asset_pair.name_on_exchange, since: cursor)
    self.cursor = response.fetch(:last)

    response.fetch(:trades)
  end
end
