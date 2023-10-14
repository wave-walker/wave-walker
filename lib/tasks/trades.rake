require "csv"

namespace :trades do
  desc "Import trades from csv file"
  task :import, [:path] => [:environment] do |t, args|
    path = args.fetch(:path)

    CSV.foreach(path, headers: %i[timestamp price, volume]) do |row|
      p(row)
      Trade.create!(
        created_at: Time.zone.at(row[:timestamp].to_i),
        price: row[:price].to_f,
        volume: row[:volume].to_f
      )
    end
  end
end
