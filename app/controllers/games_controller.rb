class GamesController < ApplicationController
  def create
    # Generate random tokens
    token_1 = SecureRandom.hex(10)
    token_2 = SecureRandom.hex(10)

    # Create initial board state (8x8 checkers board)
    initial_board_state = [
      [-1, 0, -1, 0, -1, 0, -1, 0],
      [0, -1, 0, -1, 0, -1, 0, -1],
      [-1, 0, -1, 0, -1, 0, -1, 0],
      [0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0],
      [0, 1, 0, 1, 0, 1, 0, 1],
      [1, 0, 1, 0, 1, 0, 1, 0],
      [0, 1, 0, 1, 0, 1, 0, 1]
    ]

    # Create a new game instance with tokens and initial board state
    game = Game.create!(
      token_1: token_1,
      token_2: token_2,
      board_state: initial_board_state,
      game_status: 'Waiting for opponent'
    )

    render json: { game_id: game.id, token_1: token_1, token_2: token_2 }
  end

  def show
    game = Game.find_by(id: params[:id])

    # Check if the game exists
    unless game
      render json: { error: 'Game does not exist' }, status: :not_found
      return
    end

    token = request.headers['Authorization']

    # Check if the provided token matches token_1 or token_2
    unless [game.token_1, game.token_2].include?(token)
      render json: { error: 'Wrong token' }, status: :unauthorized
      return
    end

    # If the token matches token_1, return board_state and game_status
    if token == game.token_1
      render json: { board_state: game.board_state, game_status: game.game_status }
      return
    end

    # If the token matches token_2
    if token == game.token_2
      if game.game_status == 'Waiting for opponent'
        game.update(game_status: 'Player_1 turn')
      end
      render json: { board_state: game.board_state, game_status: game.game_status }
      return
    end
  end
end
