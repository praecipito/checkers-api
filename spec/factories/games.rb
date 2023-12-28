FactoryBot.define do
  factory :game do
    token_1 { 'token1' }
    token_2 { 'token2' }
    game_status { 'Waiting for opponent' }
    board_state { [
      [-1, 0, -1, 0, -1, 0, -1, 0],
      [0, -1, 0, -1, 0, -1, 0, -1],
      [-1, 0, -1, 0, -1, 0, -1, 0],
      [0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0],
      [0, 1, 0, 1, 0, 1, 0, 1],
      [1, 0, 1, 0, 1, 0, 1, 0],
      [0, 1, 0, 1, 0, 1, 0, 1]
    ] }
    player_1_pieces { 12 }
    player_2_pieces { 12 }
  end
end
