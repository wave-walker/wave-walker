class AssetPairsController < ApplicationController
  def index
    @asset_pairs = AssetPair.order(Arel.sql("import_state = 'importing' DESC"))
      .order(import_state: :desc).order(:name)
  end
end
