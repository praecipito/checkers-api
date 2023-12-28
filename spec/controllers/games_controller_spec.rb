require 'rails_helper'

RSpec.describe GamesController, type: :controller do
  describe 'POST #create' do
    it 'creates a new game and returns valid parameters' do
      post :create

      expect(response).to have_http_status(:created)
      expect(response.content_type).to include('application/json')

      json_response = JSON.parse(response.body)
      expect(json_response).to have_key('game_id')
      expect(json_response).to have_key('token_1')
      expect(json_response).to have_key('token_2')
    end
  end

  describe 'GET #show' do
    let(:game) { create(:game, token_1: 'token1', token_2: 'token2', game_status: 'Waiting for opponent') }

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
end
