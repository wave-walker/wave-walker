require "csv"

namespace :trades do
  desc "Import trades from csv file"
  task :import, [:path] => [:environment] do |t, args|
    path = args.fetch(:path)

    Dir["#{path}*USD.csv"].each do |asset_path|
      asset_name = asset_path.match(/\/(?<asset>[\d,A-Z]+)USD.csv\z/)[:asset]
      asset = Asset.find_or_create_by!(name: asset_name)

      trades = []

      puts "Importing #{asset.name} trades... "

      CSV.foreach(asset_path, headers: %i[timestamp price, volume]) do |row|
        trades << {
          asset_id: asset.id,
          price: row[:price].to_f,
          volume: row[:volume].to_f,
          created_at: Time.zone.at(row[:timestamp].to_i)
        }

        if trades.size == 10000
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
