# frozen_string_literal: true

class Strategy < ApplicationRecord
  has_many :strategy_backtests, dependent: :destroy

  enum :entry_on, { bullish: 'bullish', bullish_or_neutral: 'bullish_or_neutral' }
  enum :exit_on, { neutral_or_bearish: 'neutral_or_bearish', bearish_only: 'bearish_only' }

  # Rails generates enum predicates (bullish?, neutral_or_bearish?, etc.) based on the
  # value names. These aliases add semantic context (entry vs. exit) so call sites read
  # as intent rather than implementation detail.
  def entry_bullish? = bullish?
  def entry_bullish_or_neutral? = bullish_or_neutral?
  def exit_neutral_or_bearish? = neutral_or_bearish?
  def exit_bearish_only? = bearish_only?
end
