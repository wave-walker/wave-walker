# frozen_string_literal: true

require 'csv'

namespace :trades do # rubocop:todo Metrics/BlockLength
  desc 'Import trades from csv file'
  task :import, [:path] => [:environment] do |_t, args| # rubocop:todo Metrics/BlockLength
    path = args.fetch(:path)

    AssetSyncService.call

    Asset.find_each do |asset|
      puts "Importing #{asset.name} trades... "

      asset_path = "#{path}#{asset.name}USD.csv"

      next unless File.exist?(asset_path)

      trades = []
      current_id = 1

      CSV.foreach(asset_path, headers: %i[timestamp price volume]) do |row|
        trades << {
          id: current_id,
          asset_id: asset.id,
          price: row[:price].to_f,
          volume: row[:volume].to_f,
          created_at: Time.zone.at(row[:timestamp].to_i)
        }

        current_id += 1

        if trades.size == 100_000
          puts "Inserting #{trades.size} trades..."
          Trade.insert_all(trades) # rubocop:todo Rails/SkipsModelValidations
          trades = []
        end
      end

      Trade.insert_all(trades) if trades.present? # rubocop:todo Rails/SkipsModelValidations

      puts 'Done!'
    end
  end
end