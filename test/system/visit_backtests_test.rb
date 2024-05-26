# frozen_string_literal: true

require 'application_system_test_case'

class VisitBacktestsTest < ApplicationSystemTestCase
  test 'shows backtests with ranke and gain' do
    Backtest.create!(asset_pair: asset_pairs(:btcusd), duration: 1.hour)
            .tap { |backtest| backtest.update!(current_value: 0) }

    visit '/'

    click_on 'Backtests'

    assert_text 'Rank: 1 ATOMUSD (1D) - $10,000.00 (0.000%)'
    assert_text 'Rank: 2 BTCUSD (1H) - $0.00 (-100.000%)'
  end
end
