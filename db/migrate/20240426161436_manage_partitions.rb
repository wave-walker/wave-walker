# frozen_string_literal: true

class ManagePartitions < ActiveRecord::Migration[7.1]
  def up
    execute <<~SQL.squish
      CREATE TABLE IF NOT EXISTS asset_pair_1_trades PARTITION OF trades FOR VALUES IN (1);
      CREATE TABLE IF NOT EXISTS asset_pair_2_trades PARTITION OF trades FOR VALUES IN (2);
    SQL

    execute <<~SQL.squish
      CREATE FUNCTION create_partition_for_asset_pair()
      RETURNS TRIGGER AS $$
      DECLARE
        asset_pair_id INTEGER;
      BEGIN
        asset_pair_id := NEW.id;
        EXECUTE 'CREATE TABLE IF NOT EXISTS asset_pair_' || asset_pair_id || '_trades PARTITION OF trades FOR VALUES IN (' || asset_pair_id || ')';
        EXECUTE 'CREATE TABLE IF NOT EXISTS asset_pair_' || asset_pair_id || '_ohlcs PARTITION OF ohlcs FOR VALUES IN (' || asset_pair_id || ')';
        EXECUTE 'CREATE TABLE IF NOT EXISTS asset_pair_' || asset_pair_id || '_smoothed_moving_averages PARTITION OF smoothed_moving_averages FOR VALUES IN (' || asset_pair_id || ')';
        EXECUTE 'CREATE TABLE IF NOT EXISTS asset_pair_' || asset_pair_id || '_smoothed_trends PARTITION OF smoothed_trends FOR VALUES IN (' || asset_pair_id || ')';
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    SQL

    execute <<~SQL.squish
      CREATE FUNCTION drop_partition_for_asset_pair()
      RETURNS TRIGGER AS $$
      DECLARE
        asset_pair_id INTEGER;
      BEGIN
        asset_pair_id := OLD.id;
        EXECUTE 'ALTER TABLE smoothed_trends DETACH PARTITION asset_pair_' || asset_pair_id || '_smoothed_trends' CASCADE;
        EXECUTE 'ALTER TABLE smoothed_moving_averages DETACH PARTITION asset_pair_' || asset_pair_id || '_smoothed_moving_averages' CASCADE;
        EXECUTE 'ALTER TABLE ohlcs DETACH PARTITION asset_pair_' || asset_pair_id || '_ohlcs' CASCADE;
        EXECUTE 'ALTER TABLE trades DETACH PARTITION asset_pair_' || asset_pair_id || '_trades' CASCADE;
        EXECUTE 'DROP TABLE asset_pair_' || asset_pair_id || '_smoothed_trends' CASCADE;
        EXECUTE 'DROP TABLE asset_pair_' || asset_pair_id || '_smoothed_moving_averages' CASCADE;
        EXECUTE 'DROP TABLE asset_pair_' || asset_pair_id || '_ohlcs' CASCADE;
        EXECUTE 'DROP TABLE asset_pair_' || asset_pair_id || '_trades' CASCADE;
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    SQL

    execute <<~SQL.squish
      CREATE TRIGGER create_partition_for_asset_pair
      AFTER INSERT ON asset_pairs
      FOR EACH ROW EXECUTE FUNCTION create_partition_for_asset_pair();
    SQL

    execute <<~SQL.squish
      CREATE TRIGGER drop_partition_for_asset_pair
      AFTER DELETE ON asset_pairs
      FOR EACH ROW EXECUTE FUNCTION drop_partition_for_asset_pair();
    SQL
  end

  def down
    execute <<~SQL.squish
      DROP TABLE asset_pair_1_trades;
      DROP TABLE asset_pair_2_trades;
      DROP TRIGGER create_partition_for_asset_pair ON asset_pairs;
      DROP TRIGGER drop_partition_for_asset_pair ON asset_pairs;
      DROP FUNCTION create_partition_for_asset_pair();
      DROP FUNCTION drop_partition_for_asset_pair()
    SQL
  end
end
