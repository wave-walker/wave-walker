class SmoothedTrendService
  def self.call(**) = new(**).call

  def initialize(ohlc:)
    @ohlc = ohlc
  end

  def call = nil

  private

  attr_reader :ohlc
end
