class Game < ApplicationRecord
  validates :game_status, inclusion: { in: ['Waiting for opponent', 'Player_1 turn', 'Player_2 turn', 'Player_1 won', 'Player_2 won'] }
end
