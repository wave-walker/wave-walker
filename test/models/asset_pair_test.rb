# frozen_string_literal: true

require 'test_helper'

class AssetPairTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test '#import' do
    asset_pair = asset_pairs(:btcusd)

    assert_changes -> { asset_pair.reload.importing? }, to: true do
      asset_pair.import
    end
  end
end
