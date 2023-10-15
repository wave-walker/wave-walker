require "csv"

namespace :trades do
  desc "Import trades from csv file"
  task :import, [:path] => [:environment] do |t, args|
    path = args.fetch(:path)

    AssetSyncService.call

    Asset.find_each do |asset|
      puts "Importing #{asset.name} trades... "

      asset_path = "#{path}#{asset.name}USD.csv"

      next unless File.exist?(asset_path)

      trades = []

      CSV.foreach(asset_path, headers: %i[timestamp price volume]) do |row|
        trades << {
          asset_id: asset.id,
          price: row[:price].to_f,
          volume: row[:volume].to_f,
          created_at: Time.zone.at(row[:timestamp].to_i)
        }

        if trades.size == 100_000
          puts "Inserting #{trades.size} trades..."
          Trade.insert_all(trades)
          trades = []
        end
      end

      Trade.insert_all(trades) if trades.present?

      puts "Done!"
    end
  end
end
