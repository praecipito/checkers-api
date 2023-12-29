require 'rails_helper'

RSpec.describe Game, type: :model do
  it 'ensures game_status is within allowed values' do
    invalid_statuses = ['waiting for opponent', 'Some other status', nil]

    invalid_statuses.each do |status|
      game = build(:game, game_status: status)

      expect(game).to_not be_valid
    end
  end

  it 'creates a new game with valid game_status and other fields' do
    game_status_options = ['Waiting for opponent', 'Player_1 turn', 'Player_2 turn', 'Player_1 won', 'Player_2 won']

    game_status_options.each do |status|
      game = build(:game, game_status: status)

      expect(game).to be_valid
      expect(game.save).to eq(true)
    end
  end
end
