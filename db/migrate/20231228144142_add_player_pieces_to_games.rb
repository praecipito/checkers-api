class AddPlayerPiecesToGames < ActiveRecord::Migration[7.0]
  def change
    add_column :games, :player_1_pieces, :integer, default: 12
    add_column :games, :player_2_pieces, :integer, default: 12
  end
end
