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
      board_state: initial_board_state,
      player_1_pieces: 12,
      player_2_pieces: 12
    )

    render json: { game_id: @game.id, token_1: @game.token_1, token_2: @game.token_2 }, status: :created
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
      render json: { error: 'Token was not provided' }, status: :unauthorized
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
      render json: { board_state: @game.board_state, game_status: @game.game_status, player_1_pieces: @game.player_1_pieces, player_2_pieces: @game.player_2_pieces }, status: :ok
      return
    # If the token matches token_2
    when @game.token_2
      if @game.game_status == 'Waiting for opponent'
        @game.update(game_status: 'Player_1 turn')
      end
      render json: { board_state: @game.board_state, game_status: @game.game_status, player_1_pieces: @game.player_1_pieces, player_2_pieces: @game.player_2_pieces }, status: :ok
      return
    end
  end

  def movements
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

    # Check if the tile exists
    unless row.between?(0, 7) && column.between?(0, 7)
      render json: { error: 'Tile does not exist' }, status: :bad_request
      return
    end

    # Check if it is the player's turn
    if (token == @game.token_1 && @game.game_status == 'Player_2 turn') || (token == @game.token_2 && @game.game_status == 'Player_1 turn')
      render json: { error: 'Not your turn' }, status: :bad_request
    elsif (token == @game.token_1 && @game.game_status == 'Player_1 turn') || (token == @game.token_2 && @game.game_status == 'Player_2 turn')
      # Check if the selected tile is empty
      if selected_tile == 0
        render json: { error: 'Empty tile' }, status: :bad_request
      # Check if the piece belongs to the player
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

  def move
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
    new_row = params[:new_row].to_i
    new_column = params[:new_column].to_i
    board_state = JSON.parse(@game.board_state)
    original_tile = board_state[row][column]
    new_tile = board_state[new_row][new_column]

    # Check if the original tile exists
    unless row.between?(0, 7) && column.between?(0, 7)
      render json: { error: 'Original tile does not exist' }, status: :bad_request
      return
    end

    # Check if the new tile exists
    unless new_row.between?(0, 7) && new_column.between?(0, 7)
      render json: { error: 'New tile does not exist' }, status: :bad_request
      return
    end

    # Check if it is the player's turn
    if (token == @game.token_1 && @game.game_status == 'Player_2 turn') || (token == @game.token_2 && @game.game_status == 'Player_1 turn')
      render json: { error: 'Not your turn' }, status: :bad_request
    elsif (token == @game.token_1 && @game.game_status == 'Player_1 turn') || (token == @game.token_2 && @game.game_status == 'Player_2 turn')
      # Check if the original tile is empty
      if original_tile == 0
        render json: { error: 'Original tile empty' }, status: :bad_request
      # Check if the piece belongs to the player
      elsif (@game.token_1 == token && original_tile == -1) || (@game.token_2 == token && original_tile == 1)
        render json: { error: 'Not your piece' }, status: :bad_request
      # Check if the new tile is occupied by your own piece
      elsif (@game.token_1 == token && new_tile == 1) || (@game.token_2 == token && new_tile == -1)
        render json: { error: 'The new tile is occupied with by own piece' }, status: :bad_request
      # Player_1 rules
      elsif @game.token_1 == token && original_tile == 1
        if new_row == row - 1 && (new_column == column - 1 || new_column == column + 1) && new_tile == 0
          board_state[row][column] = 0
          board_state[new_row][new_column] = 1
          @game.update(board_state: board_state.to_json)
          @game.update(game_status: 'Player_2 turn')
        elsif new_row == row - 2 && ((new_column == column - 2 && board_state[row - 1][column - 1] == -1) || (new_column == column + 2 && board_state[row - 1][column + 1] == -1)) && new_tile == 0
          board_state[row][column] = 0
          if new_column == column - 2
            board_state[row - 1][column - 1] = 0
          elsif new_column == column + 2
            board_state[row - 1][column + 1] = 0
          end
          board_state[new_row][new_column] = 1
          @game.update(board_state: board_state.to_json)
          @game.player_2_pieces -= 1
          if @game.player_2_pieces == 0
            @game.update(game_status: 'Player_1 won')
            render json: { board_state: @game.board_state, game_status: @game.game_status, player_1_pieces: @game.player_1_pieces, player_2_pieces: @game.player_2_pieces }
            return
          end
          @game.update(game_status: 'Player_2 turn')
        else
          render json: { error: 'Invalid move' }
          return
        end
        render json: { board_state: @game.board_state, game_status: @game.game_status, player_1_pieces: @game.player_1_pieces, player_2_pieces: @game.player_2_pieces }
      # Player_2 rules
      elsif @game.token_2 == token && original_tile == -1
        if new_row == row + 1 && (new_column == column - 1 || new_column == column + 1) && new_tile == 0
          board_state[row][column] = 0
          board_state[new_row][new_column] = -1
          @game.update(board_state: board_state.to_json)
          @game.update(game_status: 'Player_1 turn')
        elsif new_row == row + 2 && ((new_column == column - 2 && board_state[row + 1][column - 1] == 1) || (new_column == column + 2 && board_state[row + 1][column + 1] == 1)) && new_tile == 0
          board_state[row][column] = 0
          if new_column == column - 2
            board_state[row + 1][column - 1] = 0
          elsif new_column == column + 2
            board_state[row + 1][column + 1] = 0
          end
          board_state[new_row][new_column] = -1
          @game.update(board_state: board_state.to_json)
          @game.player_1_pieces -= 1
          if @game.player_1_pieces == 0
            @game.update(game_status: 'Player_2 won')
            render json: { board_state: @game.board_state, game_status: @game.game_status, player_1_pieces: @game.player_1_pieces, player_2_pieces: @game.player_2_pieces }
            return
          end
          @game.update(game_status: 'Player_1 turn')
        else
          render json: { error: 'Invalid move' }
          return
        end
        render json: { board_state: @game.board_state, game_status: @game.game_status, player_1_pieces: @game.player_1_pieces, player_2_pieces: @game.player_2_pieces }
      end
    end
  end
end
