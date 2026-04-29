# frozen_string_literal: true

class OhlcStatus < ApplicationRecord
  belongs_to :asset_pair
end
