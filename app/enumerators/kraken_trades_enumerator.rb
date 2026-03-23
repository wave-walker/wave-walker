# frozen_string_literal: true

class KrakenTradesEnumerator
  extend Limiter::Mixin

  def self.call(asset_pair, cursor:) = new(asset_pair, cursor:).to_enum(:each).lazy

  # Kraken allows 1 request per second. Allowing 50 requests ensures staying
  # under the rate limit.
  limit_method :load_trades, rate: 50, balanced: true

  def initialize(asset_pair, cursor:)
    @asset_pair = asset_pair
    @cursor = cursor
  end

  def each
    loop do
      response = load_trades
      self.cursor = response.cursor

      yield({ asset_pair:, trades: response.trades }, cursor)

      break if response.last_page?
    end
  rescue Kraken::InvalidAssetPair
    asset_pair.update!(importing: false)
  end

  private

  attr_reader :asset_pair
  attr_writer :cursor

  def cursor
    @cursor ||= asset_pair.trades.last&.created_at.to_i
  end

  def load_trades
    Kraken.trades(pair: asset_pair.name_on_exchange, since: cursor)
  end
end
