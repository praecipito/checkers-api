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
    @game = Game.create!(
      token_1: token_1,
      token_2: token_2,
      board_state: initial_board_state
    )

    render json: { game_id: @game.id, token_1: token_1, token_2: token_2 }
  end

  def show
    @game = Game.find_by(id: params[:id])

    # Check if the game exists
    unless @game
      render json: { error: 'Game does not exist' }, status: :not_found
      return
    end

    token = request.headers['Authorization']

    # Check if the token was provided
    unless token
      render json: { error: 'Token was not provided' }, status: :not_found
      return
    end

    # Check if the provided token matches token_1 or token_2
    unless [@game.token_1, @game.token_2].include?(token)
      render json: { error: 'Wrong token' }, status: :unauthorized
      return
    end

    # If the token matches token_1, return board_state and game_status
    case token
    when @game.token_1
      render json: { board_state: @game.board_state, game_status: @game.game_status }
      return
    # If the token matches token_2
    when @game.token_2
      if @game.game_status == 'Waiting for opponent'
        @game.update(game_status: 'Player_1 turn')
      end
      render json: { board_state: @game.board_state, game_status: @game.game_status }
      return
    end
  end

  def moves
    @game = Game.find_by(id: params[:id])

    # Check if the game exists
    unless @game
      render json: { error: 'Game does not exist' }, status: :not_found
      return
    end

    token = request.headers['Authorization']

    # Check if the token was provided
    unless token
      render json: { error: 'Token was not provided' }, status: :not_found
      return
    end

    # Check if the provided token matches token_1 or token_2
    unless [@game.token_1, @game.token_2].include?(token)
      render json: { error: 'Wrong token' }, status: :unauthorized
      return
    end

    # Check if the game is in progress
    unless @game.game_status == 'Player_1 turn' || @game.game_status == 'Player_2 turn'
      render json: { error: 'Game is not in progress' }, status: :bad_request
      return
    end

    row = params[:row].to_i
    column = params[:column].to_i
    board_state = JSON.parse(@game.board_state)
    selected_tile = board_state[row][column]
    possible_moves = []

    # Check if it is the player's turn
    if (token == @game.token_1 && @game.game_status == 'Player_2 turn') || (token == @game.token_2 && @game.game_status == 'Player_1 turn')
      render json: { error: 'Not your turn' }, status: :bad_request
    elsif (token == @game.token_1 && @game.game_status == 'Player_1 turn') || (token == @game.token_2 && @game.game_status == 'Player_2 turn')
      # Check if the selected tile is empty
      if selected_tile == 0
        render json: { error: 'Empty tile' }, status: :bad_request
      # Check if the piece on the :row and :column belongs to the same player as the token provided
      elsif (@game.token_1 == token && selected_tile == -1) || (@game.token_2 == token && selected_tile == 1)
        render json: { error: 'Not your piece' }, status: :bad_request
      # Player_1 rules
      elsif @game.token_1 == token && selected_tile == 1
        if row - 1 >= 0 && column - 1 >= 0 && board_state[row - 1][column - 1] == 0
          possible_moves << [row - 1, column - 1]
        end
        if row - 1 >= 0 && column + 1 <= 7 && board_state[row - 1][column + 1] == 0
          possible_moves << [row - 1, column + 1]
        end
        if row - 2 >= 0 && column - 2 >= 0 && board_state[row - 1][column - 1] == -1 && board_state[row - 2][column - 2] == 0
          possible_moves << [row - 2, column - 2]
        end
        if row - 2 >= 0 && column + 2 <= 7 && board_state[row - 1][column + 1] == -1 && board_state[row - 2][column + 2] == 0
          possible_moves << [row - 2, column + 2]
        end
        if possible_moves == []
          render json: { error: 'There are no possible moves for this piece' }, status: :bad_request
        else
          render json: { tile_requested: [row, column], possible_moves: possible_moves }
        end
      # Player_2 rules
      elsif @game.token_2 == token && selected_tile == -1
        if row + 1 <= 7 && column - 1 >= 0 && board_state[row + 1][column - 1] == 0
          possible_moves << [row + 1, column - 1]
        end
        if row + 1 <= 7 && column + 1 <= 7 && board_state[row + 1][column + 1] == 0
          possible_moves << [row + 1, column + 1]
        end
        if row + 2 <= 7 && column - 2 >= 0 && board_state[row + 1][column - 1] == 1 && board_state[row + 2][column - 2] == 0
          possible_moves << [row + 2, column - 2]
        end
        if row + 2 <= 7 && column + 2 <= 7 && board_state[row + 1][column + 1] == 1 && board_state[row + 2][column + 2] == 0
          possible_moves << [row + 2, column + 2]
        end
        if possible_moves == []
          render json: { error: 'There are no possible moves for this piece' }, status: :bad_request
        else
          render json: { tile_requested: [row, column], possible_moves: possible_moves }
        end
      end
    end
  end
end
