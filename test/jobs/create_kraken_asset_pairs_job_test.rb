# frozen_string_literal: true

require 'test_helper'

class CreateKrakenAssetPairsJobTest < ActiveJob::TestCase
  test 'inserts new asset' do
    stub_asset_pairs_api

    assert_difference 'AssetPair.count', 2 do
      CreateKrakenAssetPairsJob.perform_now
    end

    assert_equal 'ETHBTC', AssetPair.find_by!(name_on_exchange: 'ETHXBT').name
    assert_equal 'ETHUSD', AssetPair.find_by!(name_on_exchange: 'ETHUSD').name
  end

  test 'ignores existing asset' do
    stub_asset_pairs_api

    CreateKrakenAssetPairsJob.perform_now

    assert_no_difference 'AssetPair.count' do
      CreateKrakenAssetPairsJob.perform_now
    end
  end

  test 'ignores asset that are not traded agains USD or BTC' do
    Kraken.stubs(:asset_pairs).returns([
                                         { 'altname' => 'ETHADA', 'base' => 'ADA', 'quote' => 'ETH' },
                                         { 'altname' => 'ETHJPY', 'base' => 'JPY', 'quote' => 'ETH' }
                                       ])

    assert_no_difference 'AssetPair.count' do
      CreateKrakenAssetPairsJob.perform_now
    end
  end

  test 'fixes XBT kraken name to BTC' do
    stub_asset_pairs_api

    CreateKrakenAssetPairsJob.perform_now

    asset_pair = AssetPair.find_by!(name_on_exchange: 'ETHXBT')

    assert_equal 'ETHBTC', asset_pair.name
  end

  def stub_asset_pairs_api
    Kraken.stubs(:asset_pairs).returns([
                                         { 'altname' => 'ETHXBT', 'base' => 'ETH', 'quote' => 'XXBT' },
                                         { 'altname' => 'ETHUSD', 'base' => 'ETH', 'quote' => 'ZUSD' }
                                       ])
  end
end
