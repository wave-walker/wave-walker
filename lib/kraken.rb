# frozen_string_literal: true

module Kraken
  Trade = Struct.new(:price, :volume, :created_at, :action, :order_type, :misc, :id) do
    def initialize(*)
      super
      self.created_at = Time.zone.at(created_at.to_f)
      self.action = { 'b' => 'buy', 's' => 'sell' }.fetch(action)
      self.order_type = { 'm' => 'market', 'l' => 'limit' }.fetch(order_type)
    end
  end

  class Error < StandardError; end
  class RateLimitExceeded < Error; end
  class InvalidAssetPair < Error; end

  def self.trades(pair:, since:)
    response = connection.get('public/Trades', pair:, since:, count: 10_000).body
    check_response(response)

    trades = response.dig('result', pair).map { |trade_params| Trade.new(*trade_params) }

    { trades:, last: response.dig('result', 'last') }
  end

  def self.asset_pairs
    response = connection.get('public/AssetPairs').body
    check_response(response)

    response.fetch('result').values.filter_map do |pair_params|
      pair_params.slice('altname', 'quote', 'base', 'cost_decimals') if pair_params['status'] == 'online'
    end
  end

  def self.connection
    Faraday.new(url: 'https://api.kraken.com/0') do |builder|
      builder.request :json
      builder.response :json
      builder.response :raise_error
    end
  end

  def self.check_response(response)
    errors = response.fetch('error')
    raise(RateLimitExceeded, errors.join(', ')) if errors.include?('EGeneral:Too many requests')
    raise(InvalidAssetPair, errors.join(', ')) if errors.include?('EQuery:Invalid asset pair')
    raise(Error, errors.join(', ')) if errors.any?
  end

  private_class_method :connection, :check_response
end
