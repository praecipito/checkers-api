class GamesController < ApplicationController
  before_action :set_game, only: [:show, :movements, :move]

  def create
    # Create a new default game
    @game = Game.create!

    render json: { game_id: @game.id, token_1: @game.token_1, token_2: @game.token_2 }, status: :created
  end

  def show
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

    # Check if the game is in progress
    unless @game.game_status == 'Player_1 turn' || @game.game_status == 'Player_2 turn'
      render json: { error: 'Game is not in progress' }, status: :bad_request
      return
    end

    row = params[:row].to_i
    column = params[:column].to_i

    # Check if the tile exists
    unless row.between?(0, 7) && column.between?(0, 7)
      render json: { error: 'Tile does not exist' }, status: :bad_request
      return
    end

    board_state = JSON.parse(@game.board_state)
    possible_moves = []
    selected_tile = board_state[row][column]

    # Check if it is the player's turn
    if (token == @game.token_1 && @game.game_status == 'Player_2 turn') || (token == @game.token_2 && @game.game_status == 'Player_1 turn')
      render json: { error: 'Not your turn' }, status: :bad_request
    elsif (token == @game.token_1 && @game.game_status == 'Player_1 turn') || (token == @game.token_2 && @game.game_status == 'Player_2 turn')
      # Check if the selected tile is empty
      if selected_tile == 0
        render json: { error: 'Empty tile selected' }, status: :bad_request
      # Check if the piece belongs to the player
      elsif (@game.token_1 == token && (selected_tile == -1 || selected_tile == -11)) || (@game.token_2 == token && (selected_tile == 1 || selected_tile == 11))
        render json: { error: "Opponent's piece selected" }, status: :bad_request
      # Check if the piece belongs to the player and if there are possible moves for player 1
      elsif @game.token_1 == token && (selected_tile == 1 || selected_tile == 11)
        # If the piece is a king or not, check if there are possible moves for player 1
        if row - 1 >= 0 && column - 1 >= 0 && board_state[row - 1][column - 1] == 0
          possible_moves << [row - 1, column - 1]
        end
        if row - 1 >= 0 && column + 1 <= 7 && board_state[row - 1][column + 1] == 0
          possible_moves << [row - 1, column + 1]
        end
        if row - 2 >= 0 && column - 2 >= 0 && (board_state[row - 1][column - 1] == -1 || board_state[row - 1][column - 1] == -11) && board_state[row - 2][column - 2] == 0
          possible_moves << [row - 2, column - 2]
        end
        if row - 2 >= 0 && column + 2 <= 7 && (board_state[row - 1][column + 1] == -1 || board_state[row - 1][column + 1] == -11) && board_state[row - 2][column + 2] == 0
          possible_moves << [row - 2, column + 2]
        end
        # If the piece is a king, check if there are possible moves for player 1
        if selected_tile == 11
          if row + 1 <= 7 && column - 1 >= 0 && board_state[row + 1][column - 1] == 0
            possible_moves << [row + 1, column - 1]
          end
          if row + 1 <= 7 && column + 1 <= 7 && board_state[row + 1][column + 1] == 0
            possible_moves << [row + 1, column + 1]
          end
          if row + 2 <= 7 && column - 2 >= 0 && (board_state[row + 1][column - 1] == -1 || board_state[row + 1][column - 1] == -11) && board_state[row + 2][column - 2] == 0
            possible_moves << [row + 2, column - 2]
          end
          if row + 2 <= 7 && column + 2 <= 7 && (board_state[row + 1][column + 1] == -1 || board_state[row + 1][column + 1] == -11) && board_state[row + 2][column + 2] == 0
            possible_moves << [row + 2, column + 2]
          end
        end
        if possible_moves == []
          render json: { message: 'There are no possible moves for this piece' }, status: :ok
        else
          render json: { tile_requested: [row, column], possible_moves: possible_moves }, status: :ok
        end
      # Check if the piece belongs to the player and if there are possible moves for player 2
      elsif @game.token_2 == token && (selected_tile == -1 || selected_tile == -11)
        # If the piece is a king, check if there are possible moves for player 2
        if selected_tile == -11
          if row - 1 >= 0 && column - 1 >= 0 && board_state[row - 1][column - 1] == 0
            possible_moves << [row - 1, column - 1]
          end
          if row - 1 >= 0 && column + 1 <= 7 && board_state[row - 1][column + 1] == 0
            possible_moves << [row - 1, column + 1]
          end
          if row - 2 >= 0 && column - 2 >= 0 && (board_state[row - 1][column - 1] == 1 || board_state[row - 1][column - 1] == 11) && board_state[row - 2][column - 2] == 0
            possible_moves << [row - 2, column - 2]
          end
          if row - 2 >= 0 && column + 2 <= 7 && (board_state[row - 1][column + 1] == 1 || board_state[row - 1][column + 1] == 11) && board_state[row - 2][column + 2] == 0
            possible_moves << [row - 2, column + 2]
          end
        end
        # If the piece is a king or not, check if there are possible moves for player 2
        if row + 1 <= 7 && column - 1 >= 0 && board_state[row + 1][column - 1] == 0
          possible_moves << [row + 1, column - 1]
        end
        if row + 1 <= 7 && column + 1 <= 7 && board_state[row + 1][column + 1] == 0
          possible_moves << [row + 1, column + 1]
        end
        if row + 2 <= 7 && column - 2 >= 0 && (board_state[row + 1][column - 1] == 1 || board_state[row + 1][column - 1] == 11) && board_state[row + 2][column - 2] == 0
          possible_moves << [row + 2, column - 2]
        end
        if row + 2 <= 7 && column + 2 <= 7 && (board_state[row + 1][column + 1] == 1 || board_state[row + 1][column + 1] == 11) && board_state[row + 2][column + 2] == 0
          possible_moves << [row + 2, column + 2]
        end
        if possible_moves == []
          render json: { message: 'There are no possible moves for this piece' }, status: :ok
        else
          render json: { tile_requested: [row, column], possible_moves: possible_moves }, status: :ok
        end
      end
    end
  end

  def move
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

    # Check if the game is in progress
    unless @game.game_status == 'Player_1 turn' || @game.game_status == 'Player_2 turn'
      render json: { error: 'Game is not in progress' }, status: :bad_request
      return
    end

    row = params[:row].to_i
    column = params[:column].to_i

    # Check if the original tile exists
    unless row.between?(0, 7) && column.between?(0, 7)
      render json: { error: 'Original tile does not exist' }, status: :bad_request
      return
    end

    new_row = params[:new_row].to_i
    new_column = params[:new_column].to_i

    # Check if the new tile exists
    unless new_row.between?(0, 7) && new_column.between?(0, 7)
      render json: { error: 'New tile does not exist' }, status: :bad_request
      return
    end

    board_state = JSON.parse(@game.board_state)
    original_tile = board_state[row][column]
    new_tile = board_state[new_row][new_column]

    # Check if it is the player's turn
    if (token == @game.token_1 && @game.game_status == 'Player_2 turn') || (token == @game.token_2 && @game.game_status == 'Player_1 turn')
      render json: { error: 'Not your turn' }, status: :bad_request
      return
    elsif (token == @game.token_1 && @game.game_status == 'Player_1 turn') || (token == @game.token_2 && @game.game_status == 'Player_2 turn')
      # Check if the original tile is empty
      if original_tile == 0
        render json: { error: 'Original tile empty' }, status: :bad_request
        return
      # Check if the piece belongs to the player
      elsif (@game.token_1 == token && (original_tile == -1 || original_tile == -11)) || (@game.token_2 == token && (original_tile == 1 || original_tile == 11))
        render json: { error: "The original tile is occupied by your opponent's piece" }, status: :bad_request
        return
      # Check if the new tile is occupied by your own piece
      elsif (@game.token_1 == token && (new_tile == 1 || new_tile == 11)) || (@game.token_2 == token && (new_tile == -1 || new_tile == -11))
        render json: { error: 'The new tile is occupied by own piece' }, status: :bad_request
        return
      # Player_1 rules
      elsif @game.token_1 == token && (original_tile == 1 || original_tile == 11)
        if new_row == row - 1 && (new_column == column - 1 || new_column == column + 1) && new_tile == 0
          board_state[row][column] = 0
          if original_tile == 11 || new_row == 0
            board_state[new_row][new_column] = 11
          else
            board_state[new_row][new_column] = 1
          end
          @game.update(board_state: board_state.to_json)
          @game.update(game_status: 'Player_2 turn')
        elsif new_row == row - 2 && ((new_column == column - 2 && (board_state[row - 1][column - 1] == -1 || board_state[row - 1][column - 1] == -11)) || (new_column == column + 2 && (board_state[row - 1][column + 1] == -1 || board_state[row - 1][column + 1] == -11))) && new_tile == 0
          board_state[row][column] = 0
          if new_column == column - 2
            board_state[row - 1][column - 1] = 0
          elsif new_column == column + 2
            board_state[row - 1][column + 1] = 0
          end
          if original_tile == 11 || new_row == 0
            board_state[new_row][new_column] = 11
          else
            board_state[new_row][new_column] = 1
          end
          @game.update(board_state: board_state.to_json)
          @game.player_2_pieces -= 1
          if @game.player_2_pieces == 0
            @game.update(game_status: 'Player_1 won')
            render json: { board_state: @game.board_state, game_status: @game.game_status, player_1_pieces: @game.player_1_pieces, player_2_pieces: @game.player_2_pieces }, status: :ok
            return
          end
          @game.update(game_status: 'Player_2 turn')
        # Player_1 king rules
        elsif original_tile == 11 && new_row == row + 1 && (new_column == column - 1 || new_column == column + 1) && new_tile == 0
          board_state[row][column] = 0
          board_state[new_row][new_column] = 11
          @game.update(board_state: board_state.to_json)
          @game.update(game_status: 'Player_2 turn')
        elsif original_tile == 11 && new_row == row + 2 && ((new_column == column - 2 && (board_state[row + 1][column - 1] == -1 || board_state[row + 1][column - 1] == -11)) || (new_column == column + 2 && (board_state[row + 1][column + 1] == -1 || board_state[row + 1][column + 1] == -11))) && new_tile == 0
          if new_column == column - 2
            board_state[row + 1][column - 1] = 0
          elsif new_column == column + 2
            board_state[row + 1][column + 1] = 0
          end
          board_state[new_row][new_column] = 11
          @game.update(board_state: board_state.to_json)
          @game.player_2_pieces -= 1
          if @game.player_2_pieces == 0
            @game.update(game_status: 'Player_1 won')
            render json: { board_state: @game.board_state, game_status: @game.game_status, player_1_pieces: @game.player_1_pieces, player_2_pieces: @game.player_2_pieces }, status: :ok
            return
          end
          @game.update(game_status: 'Player_2 turn')
        else
          render json: { error: 'Invalid move' }, status: :bad_request
          return
        end
        render json: { board_state: @game.board_state, game_status: @game.game_status, player_1_pieces: @game.player_1_pieces, player_2_pieces: @game.player_2_pieces }
      # Player_2 rules
      elsif @game.token_2 == token && (original_tile == -1 || original_tile == -11)
        if new_row == row + 1 && (new_column == column - 1 || new_column == column + 1) && new_tile == 0
          board_state[row][column] = 0
          if original_tile == -11 || new_row == 7
            board_state[new_row][new_column] = -11
          else
            board_state[new_row][new_column] = -1
          end
          @game.update(board_state: board_state.to_json)
          @game.update(game_status: 'Player_1 turn')
        elsif new_row == row + 2 && ((new_column == column - 2 && (board_state[row + 1][column - 1] == 1 || board_state[row + 1][column - 1] == 11)) || (new_column == column + 2 && (board_state[row + 1][column + 1] == 1 || board_state[row + 1][column + 1] == 11))) && new_tile == 0
          board_state[row][column] = 0
          if new_column == column - 2
            board_state[row + 1][column - 1] = 0
          elsif new_column == column + 2
            board_state[row + 1][column + 1] = 0
          end
          if original_tile == -11 || new_row == 7
            board_state[new_row][new_column] = -11
          else
            board_state[new_row][new_column] = -1
          end
          @game.update(board_state: board_state.to_json)
          @game.player_1_pieces -= 1
          if @game.player_1_pieces == 0
            @game.update(game_status: 'Player_2 won')
            render json: { board_state: @game.board_state, game_status: @game.game_status, player_1_pieces: @game.player_1_pieces, player_2_pieces: @game.player_2_pieces }, status: :ok
            return
          end
          @game.update(game_status: 'Player_1 turn')
        # Player_2 king rules
        elsif original_tile == -11 && new_row == row - 1 && (new_column == column - 1 || new_column == column + 1) && new_tile == 0
          board_state[row][column] = 0
          board_state[new_row][new_column] = -11
          @game.update(board_state: board_state.to_json)
          @game.update(game_status: 'Player_2 turn')
        elsif original_tile == -11 && new_row == row - 2 && ((new_column == column - 2 && (board_state[row - 1][column - 1] == 1 || board_state[row - 1][column - 1] == 11)) || (new_column == column + 2 && (board_state[row - 1][column + 1] == 1 || board_state[row - 1][column + 1] == 11))) && new_tile == 0
          if new_column == column - 2
            board_state[row - 1][column - 1] = 0
          elsif new_column == column + 2
            board_state[row - 1][column + 1] = 0
          end
          board_state[new_row][new_column] = -11
          @game.update(board_state: board_state.to_json)
          @game.player_2_pieces -= 1
          if @game.player_2_pieces == 0
            @game.update(game_status: 'Player_1 won')
            render json: { board_state: @game.board_state, game_status: @game.game_status, player_1_pieces: @game.player_1_pieces, player_2_pieces: @game.player_2_pieces }, status: :ok
            return
          end
          @game.update(game_status: 'Player_2 turn')
        else
          render json: { error: 'Invalid move' }
          return
        end
        render json: { board_state: @game.board_state, game_status: @game.game_status, player_1_pieces: @game.player_1_pieces, player_2_pieces: @game.player_2_pieces }, status: :ok
      end
    end
  end

  private

  def set_game
    @game = Game.find_by(id: params[:id])
  end
end
