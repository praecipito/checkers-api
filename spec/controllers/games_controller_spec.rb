require 'rails_helper'

RSpec.describe GamesController, type: :controller do
  describe 'POST #create' do
    it 'creates a new game and returns valid parameters' do
      post :create

      expect(response).to have_http_status(:created)
      expect(response.content_type).to include('application/json')

      json_response = JSON.parse(response.body)
      expect(json_response).to include('game_id', 'token_1', 'token_2')
    end
  end

  describe 'GET #show' do
    let(:game) { create(:game, token_1: SecureRandom.hex(10), token_2: SecureRandom.hex(10)) }

    context 'when the game does not exist' do
      before { get :show, params: { id: 'invalid_id', row: 0, column: 0 } }

      it 'returns a not found error' do
        expect_error_response(:not_found, 'Game does not exist')
      end
    end

    context 'when the token was not provided' do
      before { get :show, params: { id: game.id, row: 0, column: 0 } }

      it 'returns an unauthorized error' do
        expect_error_response(:unauthorized, 'Token was not provided')
      end
    end

    context 'when the token is invalid' do
      before do
        request.headers['Authorization'] = 'InvalidToken'
        get :show, params: { id: game.id, row: 0, column: 0 }
      end

      it 'returns an unauthorized error' do
        expect_error_response(:unauthorized, 'Wrong token')
      end
    end

    context 'when token matches token_1' do
      before do
        request.headers['Authorization'] = game.token_1
        get :show, params: { id: game.id }
      end

      it 'returns board_state, game_status, and player pieces with status ok' do
        expect(response).to have_http_status(:ok)
        parsed_response = JSON.parse(response.body)
        expect(parsed_response).to include('board_state', 'game_status', 'player_1_pieces', 'player_2_pieces')
        expect(parsed_response['game_status']).to eq(game.game_status)
      end
    end

    context 'when token matches token_2 and game_status is "Waiting for opponent"' do
      before do
        request.headers['Authorization'] = game.token_2
        get :show, params: { id: game.id }
      end

      it 'updates game_status and returns board_state, game_status, and player pieces with status ok' do
        expect(response).to have_http_status(:ok)
        parsed_response = JSON.parse(response.body)
        expect(parsed_response).to include('board_state', 'game_status', 'player_1_pieces', 'player_2_pieces')
        expect(parsed_response['game_status']).to eq('Player_1 turn')
      end
    end
  end

  describe 'GET #movements' do
    let(:game) { create(:game, game_status: 'Player_1 turn', token_1: SecureRandom.hex(10), token_2: SecureRandom.hex(10), board_state: "[[-1, 0, -1, 0, -1, 0, -1, 0],[0, -1, 0, -1, 0, -1, 0, -1],[-1, 0, -1, 0, -1, 0, -1, 0],[0, 0, 0, 0, 0, 11, 0, 0],[0, 0, -1, 0, 0, 0, -11, 0],[0, 1, 0, 1, 0, 1, 0, 0],[1, 0, 1, 0, 1, 0, 1, 0],[0, 1, 0, 1, 0, 1, 0, 1]]") }

    context 'when the game does not exist' do
      before { get :movements, params: { id: 'invalid_id', row: 0, column: 0 } }

      it 'returns a not found error' do
        expect_error_response(:not_found, 'Game does not exist')
      end
    end

    context 'when the token was not provided' do
      before { get :movements, params: { id: game.id, row: 0, column: 0 } }

      it 'returns an unauthorized error' do
        expect_error_response(:unauthorized, 'Token was not provided')
      end
    end

    context 'when the token is invalid' do
      before do
        request.headers['Authorization'] = 'InvalidToken'
        get :movements, params: { id: game.id, row: 0, column: 0 }
      end

      it 'returns an unauthorized error' do
        expect_error_response(:unauthorized, 'Wrong token')
      end
    end

    context 'when the game is not in progress' do
      before do
        game.update(game_status: 'Player_1 won')
        request.headers['Authorization'] = game.token_1
        get :movements, params: { id: game.id, row: 0, column: 0 }
      end

      it 'returns a bad request error' do
        expect_error_response(:bad_request, 'Game is not in progress')
      end
    end

    context 'when the tile coordinates are invalid' do
      before do
        request.headers['Authorization'] = game.token_1
        get :movements, params: { id: game.id, row: 8, column: 8 }
      end

      it 'returns a bad request error' do
        expect_error_response(:bad_request, 'Tile does not exist')
      end
    end

    context "when it is not the player's turn" do
      before do
        request.headers['Authorization'] = game.token_2
        get :movements, params: { id: game.id, row: 0, column: 0 }
      end

      it 'returns a bad request error' do
        expect_error_response(:bad_request, 'Not your turn')
      end
    end

    context 'when and empty tile is selected' do
      before do
        request.headers['Authorization'] = game.token_1
        get :movements, params: { id: game.id, row: 4, column: 0 }
      end

      it 'returns a bad request error' do
        expect_error_response(:bad_request, 'Empty tile selected')
      end
    end

    context "when a tile with an opponent's piece is selected" do
      before do
        request.headers['Authorization'] = game.token_1
        get :movements, params: { id: game.id, row: 0, column: 0 }
      end

      it 'returns a bad request error' do
        expect_error_response(:bad_request, "Opponent's piece selected")
      end
    end

    context "when there are no possible movements" do
      before do
        request.headers['Authorization'] = game.token_1
        get :movements, params: { id: game.id, row: 6, column: 0 }
      end

      it 'returns a bad request error' do
        expect_error_response(:bad_request, 'There are no possible movements for this piece')
      end
    end

    context "when a regular piece has possible movements both to eat an opponent's piece and just to move" do
      before do
        request.headers['Authorization'] = game.token_1
        get :movements, params: { id: game.id, row: 5, column: 1 }
      end

      it 'returns the possible movements with status ok' do
        expect(response).to have_http_status(:ok)
        parsed_response = JSON.parse(response.body)
        expect(parsed_response['possible_movements']).to eq([[4, 0], [3, 3]])
      end
    end

    context "when a king piece has possible movements both to eat an opponent's piece and just to move in the reverse direction" do
      before do
        request.headers['Authorization'] = game.token_1
        get :movements, params: { id: game.id, row: 3, column: 5 }
      end

      it 'returns the possible movements with status ok' do
        expect(response).to have_http_status(:ok)
        parsed_response = JSON.parse(response.body)
        expect(parsed_response['possible_movements']).to eq([[4, 4], [5, 7]])
      end
    end
  end

  describe 'PATCH #move' do
    let(:game) { create(:game, game_status: 'Player_1 turn', token_1: SecureRandom.hex(10), token_2: SecureRandom.hex(10), board_state: "[[-1, 0, -1, 0, -1, 0, -1, 0],[0, -1, 0, -1, 0, -1, 0, -1],[-1, 0, -1, 0, -1, 0, -1, 0],[0, 0, 0, 0, 0, 11, 0, 0],[0, 0, -1, 0, 0, 0, -11, 0],[0, 1, 0, 1, 0, 1, 0, 0],[1, 0, 1, 0, 1, 0, 1, 0],[0, 1, 0, 1, 0, 1, 0, 1]]") }

    context 'when the game does not exist' do
      before { patch :move, params: { id: 'invalid_id', row: 0, column: 0, new_row: 1, new_column: 1 } }

      it 'returns a not found error' do
        expect_error_response(:not_found, 'Game does not exist')
      end
    end

    context 'when the token was not provided' do
      before { patch :move, params: { id: game.id, row: 0, column: 0, new_row: 1, new_column: 1 } }

      it 'returns an unauthorized error' do
        expect_error_response(:unauthorized, "Token was not provided")
      end
    end

    context 'when the token is invalid' do
      before do
        request.headers['Authorization'] = 'InvalidToken'
        patch :move, params: { id: game.id, row: 0, column: 0, new_row: 1, new_column: 1 }
      end

      it 'returns an unauthorized error' do
        expect_error_response(:unauthorized, "Wrong token")
      end
    end

    context 'when the game is not in progress' do
      before do
        game.update(game_status: 'Player_1 won')
        request.headers['Authorization'] = game.token_1
        patch :move, params: { id: game.id, row: 0, column: 0, new_row: 1, new_column: 1 }
      end

      it 'returns a bad request error' do
        expect_error_response(:bad_request, "Game is not in progress")
      end
    end

    context 'when the original tile coordinates are invalid' do
      before do
        request.headers['Authorization'] = game.token_1
        patch :move, params: { id: game.id, row: 8, column: 8, new_row: 7, new_column: 7 }
      end

      it 'returns a bad request error' do
        expect_error_response(:bad_request, "Original tile does not exist")
      end
    end

    context 'when the new tile coordinates are invalid' do
      before do
        request.headers['Authorization'] = game.token_1
        patch :move, params: { id: game.id, row: 7, column: 7, new_row: 8, new_column: 8 }
      end

      it 'returns a bad request error' do
        expect_error_response(:bad_request, "New tile does not exist")
      end
    end

    context "when it is not the player's turn" do
      before do
        request.headers['Authorization'] = game.token_2
        patch :move, params: { id: game.id, row: 7, column: 7, new_row: 6, new_column: 6 }
      end

      it 'returns a bad request error' do
        expect_error_response(:bad_request, "Not your turn")
      end
    end

    context "when the original tile is empty" do
      before do
        request.headers['Authorization'] = game.token_1
        patch :move, params: { id: game.id, row: 4, column: 0, new_row: 3, new_column: 1 }
      end

      it 'returns a bad request error' do
        expect_error_response(:bad_request, "Original tile is empty")
      end
    end

    context "when the piece on the original tile does not belong to the player" do
      before do
        request.headers['Authorization'] = game.token_1
        patch :move, params: { id: game.id, row: 0, column: 0, new_row: 1, new_column: 1 }
      end

      it 'returns a bad request error' do
        expect_error_response(:bad_request, "The original tile is occupied by your opponent's piece")
      end
    end

    context "when the piece on the new tile belongs to the same player" do
      before do
        request.headers['Authorization'] = game.token_1
        patch :move, params: { id: game.id, row: 6, column: 0, new_row: 5, new_column: 1 }
      end

      it 'returns a bad request error' do
        expect_error_response(:bad_request, "The new tile is occupied by one of your pieces")
      end
    end

    context "when a player's regular piece movement is valid" do
      before do
        request.headers['Authorization'] = game.token_1
        patch :move, params: { id: game.id, row: 5, column: 1, new_row: 4, new_column: 0 }
      end

      it "updates the board_state and returns the new board_state, game_status, and both players' pieces with status ok" do
        expect(response).to have_http_status(:ok)
        parsed_response = JSON.parse(response.body)
        expect(parsed_response).to include('board_state', 'game_status', 'player_1_pieces', 'player_2_pieces')
        expect(parsed_response['game_status']).to eq('Player_2 turn')
      end
    end

    context "when a player's regular piece eats the opponent's regular piece" do
      before do
        request.headers['Authorization'] = game.token_1
        patch :move, params: { id: game.id, row: 5, column: 1, new_row: 3, new_column: 3 }
      end

      it "updates the board_state, the opponent's pieces and the game status and returns the new board_state, game_status, and both players' pieces with status ok" do
        expect(response).to have_http_status(:ok)
        parsed_response = JSON.parse(response.body)
        expect(parsed_response).to include('board_state', 'game_status', 'player_1_pieces', 'player_2_pieces')
        expect(parsed_response['game_status']).to eq('Player_2 turn')
        expect(parsed_response['player_2_pieces']).to eq(11)
      end
    end

    context "when a player's regular piece eats the opponent's king piece" do
      before do
        request.headers['Authorization'] = game.token_1
        patch :move, params: { id: game.id, row: 5, column: 5, new_row: 3, new_column: 7 }
      end

      it "updates the board_state, the opponent's pieces and the game status and returns the new board_state, game_status, and both players' pieces with status ok" do
        expect(response).to have_http_status(:ok)
        parsed_response = JSON.parse(response.body)
        expect(parsed_response).to include('board_state', 'game_status', 'player_1_pieces', 'player_2_pieces')
        expect(parsed_response['game_status']).to eq('Player_2 turn')
        expect(parsed_response['player_2_pieces']).to eq(11)
      end
    end

    context "when a player's king piece moves in the reverse direction" do
      before do
        request.headers['Authorization'] = game.token_1
        patch :move, params: { id: game.id, row: 3, column: 5, new_row: 4, new_column: 4 }
      end

      it "updates the board_state and returns the new board_state, game_status, and both players' pieces with status ok" do
        expect(response).to have_http_status(:ok)
        parsed_response = JSON.parse(response.body)
        expect(parsed_response).to include('board_state', 'game_status', 'player_1_pieces', 'player_2_pieces')
        expect(parsed_response['game_status']).to eq('Player_2 turn')
      end
    end

    context "when a player's king piece eats an opponent's piece in the reverse direction" do
      before do
        request.headers['Authorization'] = game.token_1
        patch :move, params: { id: game.id, row: 3, column: 5, new_row: 5, new_column: 7 }
      end

      it "updates the board_state, the opponent's pieces and the game statusX and returns the new board_state, game_status, and both players' pieces with status ok" do
        expect(response).to have_http_status(:ok)
        parsed_response = JSON.parse(response.body)
        expect(parsed_response).to include('board_state', 'game_status', 'player_1_pieces', 'player_2_pieces')
        expect(parsed_response['game_status']).to eq('Player_2 turn')
        expect(parsed_response['player_2_pieces']).to eq(11)
      end
    end

    context "when a player's piece eats an opponent's piece and the player wins the game" do
      before do
        game.update(player_2_pieces: 1)
        request.headers['Authorization'] = game.token_1
        patch :move, params: { id: game.id, row: 3, column: 5, new_row: 5, new_column: 7 }
      end

      it "updates the board_state, the opponent's pieces and the game status and returns the new board_state, game_status, and both players' pieces with status ok" do
        expect(response).to have_http_status(:ok)
        parsed_response = JSON.parse(response.body)
        expect(parsed_response).to include('board_state', 'game_status', 'player_1_pieces', 'player_2_pieces')
        expect(parsed_response['game_status']).to eq('Player_1 won')
        expect(parsed_response['player_2_pieces']).to eq(0)
      end
    end
  end

  private

  def expect_error_response(status, error_message)
    expect(response).to have_http_status(status)
    expect(JSON.parse(response.body)['error']).to eq(error_message)
  end
end
