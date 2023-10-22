module Kraken
  def self.trades(pair:, since:)
    response = connection.get('public/Trades', pair:, since:, count: 10000).body.fetch('result')
    { trades: response.fetch(pair), last: response.fetch('last') }
  end

  def self.assets
    connection.get('public/Assets').body.fetch('result')
  end

  def self.connection
    Faraday.new(url: 'https://api.kraken.com/0') do |builder|
      builder.request :json
      builder.response :json
      builder.response :raise_error
    end
  end

  private_class_method :connection
end