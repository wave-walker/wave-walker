namespace :asset_pairs do
  desc "TODO"
  task sync: :environment do
    Kraken.asset_pairs.keys.each do |asset_pair_name|
      AssetPair.find_or_create_by!(name: asset_pair_name)
    end
  end
end
