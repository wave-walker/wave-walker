require "test_helper"

class KrakenTest < ActiveSupport::TestCase
  class TradesTest < ActiveSupport::TestCase
    test "too many request raise an error" do
      stub_request(:get, "https://api.kraken.com/0/public/Trades?count=10000&pair=XXBTZEUR&since=0").
        to_return(
          status: 200,
          body: { error: ["EGeneral:Too many requests"] }.to_json,
          headers: { 'Content-Type' => 'application/json' })

      error = assert_raises Kraken::RateLimitExceeded do
        Kraken.trades(pair: 'XXBTZEUR', since: 0)
      end

      assert_equal "EGeneral:Too many requests", error.message
    end

    test "unkown errors raise an error" do
      stub_request(:get, "https://api.kraken.com/0/public/Trades?count=10000&pair=XXBTZEUR&since=0").
        to_return(
          status: 200,
          body: { error: ["Some unexpected happend!"] }.to_json,
          headers: { 'Content-Type' => 'application/json' })

      error = assert_raises Kraken::Error do
        Kraken.trades(pair: 'XXBTZEUR', since: 0)
      end

      assert_equal "Some unexpected happend!", error.message
    end

    test "returns the trades and the cursor position" do
      stub_request(:get, "https://api.kraken.com/0/public/Trades?count=10000&pair=XXBTZEUR&since=0").
        to_return(
          status: 200,
          body: { error: [], result: { 'XXBTZEUR' => [[1, 2, 3, 'b', 'm', 6]], last: 123456 } }.to_json,
          headers: { 'Content-Type' => 'application/json' })

      response = Kraken.trades(pair: 'XXBTZEUR', since: 0)

      assert_equal [Kraken::Trade.new(1, 2, 3, 'b', 'm', 6)], response[:trades]
      assert_equal 123456, response[:last]
    end
  end
end
