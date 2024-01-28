# frozen_string_literal: true

namespace :asset_pairs do
  desc 'TODO'
  task sync: :environment do
    Kraken.asset_pairs.each_key do |asset_pair_name|
      AssetPair.find_or_create_by!(name: asset_pair_name)
    end
  end
end
