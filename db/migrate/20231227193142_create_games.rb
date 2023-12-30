class CreateGames < ActiveRecord::Migration[7.0]
  def change
    create_table :games do |t|
      t.text :board_state, default: "[[-1, 0, -1, 0, -1, 0, -1, 0],[0, -1, 0, -1, 0, -1, 0, -1],[-1, 0, -1, 0, -1, 0, -1, 0],[0, 0, 0, 0, 0, 0, 0, 0],[0, 0, 0, 0, 0, 0, 0, 0],[0, 1, 0, 1, 0, 1, 0, 1],[1, 0, 1, 0, 1, 0, 1, 0],[0, 1, 0, 1, 0, 1, 0, 1]]"
      t.string :game_status, default: 'Waiting for opponent'
      t.string :token_1, default: SecureRandom.hex(10)
      t.string :token_2, default: SecureRandom.hex(10)

      t.timestamps
    end
  end
end
