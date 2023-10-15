module Kraken
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
