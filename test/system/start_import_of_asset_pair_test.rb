# frozen_string_literal: true

require 'application_system_test_case'

class StartImportOfAssetPairTest < ApplicationSystemTestCase
  test 'user can start importing an asset pair' do
    asset_pair = asset_pairs(:btcusd)
    visit '/'

    click_on 'Asset Pairs'
    click_on 'Import Asset Pair'

    select 'BTCUSD', from: 'Asset pair'

    assert_changes -> { asset_pair.reload.importing }, from: false, to: true do
      click_on 'Save'
      assert_text 'Importing BTCUSD'
    end

    within '#asset-pairs' do
      assert_text 'BTCUSD'
    end
  end
end
