# frozen_string_literal: true

class PartitionTradeAnalysisByAssetPairs < ActiveRecord::Migration[7.1]
  def up # rubocop:disable Metrics/AbcSize
    drop_table :smoothed_trends
    drop_table :smoothed_moving_averages
    drop_table :ohlcs

    create_table :ohlcs, primary_key: %i[asset_pair_id duration range_position],
                         options: 'PARTITION BY LIST (asset_pair_id)' do |t|
      t.bigint :asset_pair_id, null: false
      t.enum :duration, enum_type: 'timeframe', null: false
      t.bigint :range_position, null: false
      t.float :open, null: false
      t.float :high, null: false
      t.float :low, null: false
      t.float :close, null: false
      t.float :volume, null: false

      t.timestamps
    end

    create_table :smoothed_moving_averages, primary_key: %i[asset_pair_id duration range_position interval],
                                            options: 'PARTITION BY LIST (asset_pair_id)' do |t|
      t.bigint :asset_pair_id, null: false
      t.enum :duration, enum_type: 'timeframe', null: false
      t.bigint :range_position, null: false
      t.integer :interval, null: false
      t.float :value, null: false

      t.timestamp :created_at, null: false
    end

    create_table :smoothed_trends, primary_key: %i[asset_pair_id duration range_position],
                                   options: 'PARTITION BY LIST (asset_pair_id)' do |t|
      t.bigint :asset_pair_id, null: false
      t.enum :duration, enum_type: 'timeframe', null: false
      t.bigint :range_position, null: false
      t.float :fast_smma, null: false
      t.float :slow_smma, null: false
      t.enum :trend, enum_type: :trend, null: false

      t.timestamp :created_at, null: false
    end

    add_foreign_key :ohlcs, :asset_pairs, column: :asset_pair_id
    add_foreign_key :smoothed_moving_averages, :asset_pairs, column: :asset_pair_id
    add_foreign_key :smoothed_trends, :asset_pairs, column: :asset_pair_id
    add_foreign_key :smoothed_moving_averages, :ohlcs, column: %i[asset_pair_id duration range_position],
                                                       primary_key: %i[asset_pair_id duration range_position]
    add_foreign_key :smoothed_trends, :ohlcs, column: %i[asset_pair_id duration range_position],
                                              primary_key: %i[asset_pair_id duration range_position]

    execute <<-SQL.squish
      CREATE TABLE asset_pair_1_ohlcs
        PARTITION OF ohlcs
        FOR VALUES IN (1);
      CREATE TABLE asset_pair_2_ohlcs
        PARTITION OF ohlcs
        FOR VALUES IN (2);
      CREATE TABLE asset_pair_1_smoothed_moving_averages
        PARTITION OF smoothed_moving_averages
        FOR VALUES IN (1);
      CREATE TABLE asset_pair_2_smoothed_moving_averages
        PARTITION OF smoothed_moving_averages
        FOR VALUES IN (2);
      CREATE TABLE asset_pair_1_smoothed_trends
        PARTITION OF smoothed_trends
        FOR VALUES IN (1);
      CREATE TABLE asset_pair_2_smoothed_trends
        PARTITION OF smoothed_trends
        FOR VALUES IN (2);
    SQL
  end

  def down # rubocop:disable Metrics/AbcSize
    drop_table :smoothed_trends
    drop_table :smoothed_moving_averages
    drop_table :ohlcs

    create_table :ohlcs do |t|
      t.references :asset_pair, null: false, foreign_key: true
      t.datetime :start_at, null: false
      t.enum :duration, enum_type: 'timeframe', null: false
      t.float :open, null: false
      t.float :high, null: false
      t.float :low, null: false
      t.float :close, null: false
      t.float :volume, null: false

      t.timestamps
    end

    create_table :smoothed_moving_averages, primary_key: %i[ohlc_id interval] do |t|
      t.belongs_to :ohlc, null: false, foreign_key: true, index: false
      t.integer :interval, null: false
      t.float :value, null: false

      t.timestamp :created_at, null: false
    end

    create_table :smoothed_trends, primary_key: [:ohlc_id] do |t|
      t.belongs_to :ohlc, null: false, foreign_key: true, index: false
      t.float :fast_smma, null: false
      t.float :slow_smma, null: false
      t.enum :trend, enum_type: :trend, null: false

      t.timestamp :created_at, null: false
    end
  end
end
