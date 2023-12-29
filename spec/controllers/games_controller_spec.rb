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
    let(:game) { create(:game) }

    context 'when token is not provided' do
      it 'returns status unauthorized' do
        get :show, params: { id: game.id }

        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)).to eq({ 'error' => 'Token was not provided' })
      end
    end

    context 'when provided token does not match token_1 or token_2' do
      it 'returns status unauthorized' do
        request.headers['Authorization'] = 'invalid_token'
        get :show, params: { id: game.id }

        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)).to eq({ 'error' => 'Wrong token' })
      end
    end

    context 'when token matches token_1' do
      it 'returns board_state, game_status, and player pieces with status ok' do
        request.headers['Authorization'] = 'token1'
        get :show, params: { id: game.id }

        expect(response).to have_http_status(:ok)
        parsed_response = JSON.parse(response.body)
        expect(parsed_response).to include('board_state', 'game_status', 'player_1_pieces', 'player_2_pieces')
        expect(parsed_response['game_status']).to eq(game.game_status)
      end
    end

    context 'when token matches token_2 and game_status is "Waiting for opponent"' do
      it 'updates game_status and returns board_state, game_status, and player pieces with status ok' do
        request.headers['Authorization'] = 'token2'
        get :show, params: { id: game.id }

        expect(response).to have_http_status(:ok)
        parsed_response = JSON.parse(response.body)
        expect(parsed_response).to include('board_state', 'game_status', 'player_1_pieces', 'player_2_pieces')
        expect(parsed_response['game_status']).to eq('Player_1 turn')
      end
    end

    context 'when token matches token_2 but game_status is not "Waiting for opponent"' do
      it 'returns board_state, game_status, and player pieces with status ok' do
        game.update(game_status: 'Player_1 turn')
        request.headers['Authorization'] = 'token2'
        get :show, params: { id: game.id }

        expect(response).to have_http_status(:ok)
        parsed_response = JSON.parse(response.body)
        expect(parsed_response).to include('board_state', 'game_status', 'player_1_pieces', 'player_2_pieces')
        expect(parsed_response['game_status']).to eq('Player_1 turn')
      end
    end

    context 'when game does not exist' do
      it 'returns status not found' do
        get :show, params: { id: 999 }

        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)).to eq({ 'error' => 'Game does not exist' })
      end
    end
  end

  describe 'GET #movements' do
  let(:game) { create(:game, game_status: 'Player_1 turn') }

    context 'when the game does not exist' do
      before { get :movements, params: { id: 'invalid_id', row: 0, column: 0 } }

      it 'returns a not found error' do
        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)['error']).to eq('Game does not exist')
      end
    end

    context 'when the token was not provided' do
      before { get :movements, params: { id: game.id, row: 0, column: 0 } }

      it 'returns an unauthorized error' do
        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)['error']).to eq('Token was not provided')
      end
    end

    context 'when the token is invalid' do
      before do
        request.headers['Authorization'] = 'InvalidToken'
        get :movements, params: { id: game.id, row: 0, column: 0 }
      end

      it 'returns an unauthorized error' do
        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)['error']).to eq('Wrong token')
      end
    end

    context 'when the game is not in progress' do
      before do
        game.update(game_status: 'Player_1 won')
        request.headers['Authorization'] = game.token_1
        get :movements, params: { id: game.id, row: 0, column: 0 }
      end

      it 'returns a bad request error' do
        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)['error']).to eq('Game is not in progress')
      end
    end

    context 'when the tile coordinates are invalid' do
      before do
        request.headers['Authorization'] = game.token_1
        get :movements, params: { id: game.id, row: 8, column: 8 }
      end

      it 'returns a bad request error' do
        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)['error']).to eq('Tile does not exist')
      end
    end

    context "when it is not the player's turn" do
      before do
        request.headers['Authorization'] = game.token_2
        get :movements, params: { id: game.id, row: 0, column: 0 }
      end

      it 'returns a bad request error' do
        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)['error']).to eq('Not your turn')
      end
    end

    context 'when and empty tile is selected' do
      before do
        request.headers['Authorization'] = game.token_1
        get :movements, params: { id: game.id, row: 4, column: 0 }
      end

      it 'returns a bad request error' do
        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)['error']).to eq('Empty tile selected')
      end
    end

    context "when a tile with an opponent's piece is selected" do
      before do
        request.headers['Authorization'] = game.token_1
        get :movements, params: { id: game.id, row: 0, column: 0 }
      end

      it 'returns a bad request error' do
        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)['error']).to eq("Opponent's piece selected")
      end
    end


  end
end
