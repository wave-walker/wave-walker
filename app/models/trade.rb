# frozen_string_literal: true

class Trade < ApplicationRecord
  belongs_to :asset_pair
end
