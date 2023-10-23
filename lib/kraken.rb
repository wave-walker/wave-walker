module Kraken
  class RateLimitExceeded < StandardError; end
  class Error < StandardError; end

  def self.trades(pair:, since:)
    response = connection.get('public/Trades', pair:, since:, count: 10000).body
    check_response(response)

    { trades: response.dig('result', pair), last: response.dig('result', 'last') }
  end

  def self.asset_pairs
    response = connection.get('public/AssetPairs').body
    check_response(response)

    response.fetch('result')
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
    raise(Error, errors.join(', ')) if errors.any?
  end

  private_class_method :connection, :check_response
end
