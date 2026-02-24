# frozen_string_literal: true

require 'test_helper'

class CreateKrakenAssetPairsJobTest < ActiveJob::TestCase
  test 'inserts new asset' do
    stub_asset_pairs_api

    assert_difference 'AssetPair.count', 1 do
      CreateKrakenAssetPairsJob.perform_now
    end

    assert_equal 'ETHUSD', AssetPair.find_by!(name_on_exchange: 'ETHUSD').name
  end

  test 'ignores existing asset' do
    stub_asset_pairs_api

    CreateKrakenAssetPairsJob.perform_now

    assert_no_difference 'AssetPair.count' do
      CreateKrakenAssetPairsJob.perform_now
    end
  end

  test 'ignores asset that are not traded agains USD' do
    Kraken.stubs(:asset_pairs)
          .returns([
                     { 'altname' => 'ETHXBT', 'base' => 'ETH', 'quote' => 'XXBT', 'cost_decimals' => 2 },
                     { 'altname' => 'ETHJPY', 'base' => 'JPY', 'quote' => 'ETH', 'cost_decimals' => 5 }
                   ])

    assert_no_difference 'AssetPair.count' do
      CreateKrakenAssetPairsJob.perform_now
    end
  end

  test 'fixes XBT kraken name to BTC' do
    Kraken.stubs(:asset_pairs)
          .returns([
                     { 'altname' => 'XBTUSD', 'base' => 'XXBT', 'quote' => 'ZUSD', 'cost_decimals' => 5 }
                   ])

    CreateKrakenAssetPairsJob.perform_now

    asset_pair = AssetPair.find_by!(name_on_exchange: 'XBTUSD')

    assert_equal 'BTCUSD', asset_pair.name
  end

  test 'marks missing usd asset pairs as missing and disables importing' do
    asset_pair = asset_pairs(:btcusd)
    asset_pair.update!(importing: true)

    Kraken.stubs(:asset_pairs)
          .returns([
                     { 'altname' => 'ETHUSD', 'base' => 'ETH', 'quote' => 'ZUSD', 'cost_decimals' => 5 }
                   ])

    CreateKrakenAssetPairsJob.perform_now

    assert asset_pair.reload.missing_on_exchange_at.present?
    assert_not asset_pair.importing?
  end

  test 'clears missing flag when asset pair reappears' do
    asset_pair = asset_pairs(:btcusd)
    asset_pair.update!(missing_on_exchange_at: Time.current)

    Kraken.stubs(:asset_pairs)
          .returns([
                     { 'altname' => 'XBTUSD', 'base' => 'XXBT', 'quote' => 'ZUSD', 'cost_decimals' => 5 }
                   ])

    CreateKrakenAssetPairsJob.perform_now

    assert_nil asset_pair.reload.missing_on_exchange_at
  end

  def stub_asset_pairs_api
    Kraken.stubs(:asset_pairs)
          .returns([
                     { 'altname' => 'ETHUSD', 'base' => 'ETH', 'quote' => 'ZUSD', 'cost_decimals' => 5 }
                   ])
  end
end
