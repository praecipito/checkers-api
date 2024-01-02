class GamesController < ApplicationController
  before_action :set_game, only: [:show, :movements, :move]
  before_action :validations, only: [:show, :movements, :move]

  def create
    # Create a new default game
    @game = Game.create!(token_1: SecureRandom.hex(10), token_2: SecureRandom.hex(10))

    if @game
      render json: { game_id: @game.id, token_1: @game.token_1, token_2: @game.token_2 }, status: :created
    else
      render_error('Game could not be created', :bad_request)
    end
  end

  def show
    # If the token matches token_1, return board_state and game_status
    case @token
    when @game.token_1
      render_game_status
    # If the token matches token_2
    when @game.token_2
      if @game.game_status == 'Waiting for opponent'
        @game.update(game_status: 'Player_1 turn')
      end
      render_game_status
    end
  end

  def movements
    # Check if the game is in progress
    unless game_in_progress?
      render_error('Game is not in progress', :bad_request)
      return
    end

    row = params[:row].to_i
    column = params[:column].to_i

    # Check if the tile exists
    unless tile_exists?(row, column)
      render_error('Tile does not exist', :bad_request)
      return
    end

    board_state = JSON.parse(@game.board_state)
    possible_movements = []
    selected_tile = board_state[row][column]

    # Check if it is the player's turn
    if general_turn_validation(@game.token_1, 'Player_2 turn', @game.token_2, 'Player_1 turn')
      render_error('Not your turn', :bad_request)
    elsif general_turn_validation(@game.token_1, 'Player_1 turn', @game.token_2, 'Player_2 turn')
      # Check if the selected tile is empty
      if selected_tile == 0
        render_error('Empty tile selected', :bad_request)
      # Check if the piece belongs to the player
      elsif piece_validation(@game.token_1, selected_tile, -1, -11) || piece_validation(@game.token_2, selected_tile, 1, 11)
        render_error("Opponent's piece selected", :bad_request)
      # Check if the piece belongs to the player and if there are possible movements for player 1
      elsif piece_validation(@game.token_1, selected_tile, 1, 11)
        # If the piece is a king or not, check if there are possible movements for player 1
        if row - 1 >= 0 && column - 1 >= 0 && board_state[row - 1][column - 1] == 0
          possible_movements << [row - 1, column - 1]
        end
        if row - 1 >= 0 && column + 1 <= 7 && board_state[row - 1][column + 1] == 0
          possible_movements << [row - 1, column + 1]
        end
        if row - 2 >= 0 && column - 2 >= 0 && (board_state[row - 1][column - 1] == -1 || board_state[row - 1][column - 1] == -11) && board_state[row - 2][column - 2] == 0
          possible_movements << [row - 2, column - 2]
        end
        if row - 2 >= 0 && column + 2 <= 7 && (board_state[row - 1][column + 1] == -1 || board_state[row - 1][column + 1] == -11) && board_state[row - 2][column + 2] == 0
          possible_movements << [row - 2, column + 2]
        end
        # If the piece is a king, check if there are possible movements for player 1
        if selected_tile == 11
          if row + 1 <= 7 && column - 1 >= 0 && board_state[row + 1][column - 1] == 0
            possible_movements << [row + 1, column - 1]
          end
          if row + 1 <= 7 && column + 1 <= 7 && board_state[row + 1][column + 1] == 0
            possible_movements << [row + 1, column + 1]
          end
          if row + 2 <= 7 && column - 2 >= 0 && (board_state[row + 1][column - 1] == -1 || board_state[row + 1][column - 1] == -11) && board_state[row + 2][column - 2] == 0
            possible_movements << [row + 2, column - 2]
          end
          if row + 2 <= 7 && column + 2 <= 7 && (board_state[row + 1][column + 1] == -1 || board_state[row + 1][column + 1] == -11) && board_state[row + 2][column + 2] == 0
            possible_movements << [row + 2, column + 2]
          end
        end
        if possible_movements == []
          render_error('There are no possible movements for this piece', :bad_request)
        else
          render json: { tile_requested: [row, column], possible_movements: possible_movements }, status: :ok
        end
      # Check if the piece belongs to the player and if there are possible movements for player 2
      elsif piece_validation(@game.token_2, selected_tile, -1, -11)
        # If the piece is a king, check if there are possible movements for player 2
        if selected_tile == -11
          if row - 1 >= 0 && column - 1 >= 0 && board_state[row - 1][column - 1] == 0
            possible_movements << [row - 1, column - 1]
          end
          if row - 1 >= 0 && column + 1 <= 7 && board_state[row - 1][column + 1] == 0
            possible_movements << [row - 1, column + 1]
          end
          if row - 2 >= 0 && column - 2 >= 0 && (board_state[row - 1][column - 1] == 1 || board_state[row - 1][column - 1] == 11) && board_state[row - 2][column - 2] == 0
            possible_movements << [row - 2, column - 2]
          end
          if row - 2 >= 0 && column + 2 <= 7 && (board_state[row - 1][column + 1] == 1 || board_state[row - 1][column + 1] == 11) && board_state[row - 2][column + 2] == 0
            possible_movements << [row - 2, column + 2]
          end
        end
        # If the piece is a king or not, check if there are possible movements for player 2
        if row + 1 <= 7 && column - 1 >= 0 && board_state[row + 1][column - 1] == 0
          possible_movements << [row + 1, column - 1]
        end
        if row + 1 <= 7 && column + 1 <= 7 && board_state[row + 1][column + 1] == 0
          possible_movements << [row + 1, column + 1]
        end
        if row + 2 <= 7 && column - 2 >= 0 && (board_state[row + 1][column - 1] == 1 || board_state[row + 1][column - 1] == 11) && board_state[row + 2][column - 2] == 0
          possible_movements << [row + 2, column - 2]
        end
        if row + 2 <= 7 && column + 2 <= 7 && (board_state[row + 1][column + 1] == 1 || board_state[row + 1][column + 1] == 11) && board_state[row + 2][column + 2] == 0
          possible_movements << [row + 2, column + 2]
        end
        if possible_movements == []
          render_error('There are no possible movements for this piece', :bad_request)
        else
          render json: { tile_requested: [row, column], possible_movements: possible_movements }, status: :ok
        end
      end
    end
  end

  def move
    # Check if the game is in progress
    unless game_in_progress?
      render_error('Game is not in progress', :bad_request)
      return
    end

    row = params[:row].to_i
    column = params[:column].to_i

    # Check if the original tile exists
    unless tile_exists?(row, column)
      render_error('Original tile does not exist', :bad_request)
      return
    end

    new_row = params[:new_row].to_i
    new_column = params[:new_column].to_i

    # Check if the new tile exists
    unless tile_exists?(new_row, new_column)
      render_error('New tile does not exist', :bad_request)
      return
    end

    board_state = JSON.parse(@game.board_state)
    original_tile = board_state[row][column]
    new_tile = board_state[new_row][new_column]

    # Check if it is the player's turn
    if general_turn_validation(@game.token_1, 'Player_2 turn', @game.token_2, 'Player_1 turn')
      render_error('Not your turn', :bad_request)
      return
    elsif general_turn_validation(@game.token_1, 'Player_1 turn', @game.token_2, 'Player_2 turn')
      # Check if the original tile is empty
      if original_tile == 0
        render_error('Original tile is empty', :bad_request)
        return
      # Check if the piece belongs to the player
      elsif piece_validation(@game.token_1, original_tile, -1, -11) || piece_validation(@game.token_2, original_tile, 1, 11)
        render_error("The original tile is occupied by your opponent's piece", :bad_request)
        return
      # Check if the new tile is occupied by your own piece
      elsif piece_validation(@game.token_1, new_tile, 1, 11) || piece_validation(@game.token_2, new_tile, -1, -11)
        render_error('The new tile is occupied by one of your pieces', :bad_request)
        return
      # Player_1 rules
      elsif piece_validation(@game.token_1, original_tile, 1, 11)
        if new_row == row - 1 && (new_column == column - 1 || new_column == column + 1) && new_tile == 0
          board_state[row][column] = 0
          if original_tile == 11 || new_row == 0
            board_state[new_row][new_column] = 11
          else
            board_state[new_row][new_column] = 1
          end
          @game.update(board_state: board_state.to_json)
          @game.update(game_status: 'Player_2 turn')
          # EATING VALIDATION
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
            render_game_status
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
            render_game_status
            return
          end
          @game.update(game_status: 'Player_2 turn')
        else
          render_error('Invalid move', :bad_request)
          return
        end
        render_game_status
      # Player_2 rules
      elsif piece_validation(@game.token2, original_tile, -1, -11)
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
            render_game_status
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
          @game.player_1_pieces -= 1
          if @game.player_1_pieces == 0
            @game.update(game_status: 'Player_2 won')
            render_game_status
            return
          end
          @game.update(game_status: 'Player_1 turn')
        else
          render_error('Invalid move', :bad_request)
          return
        end
        render_game_status
      end
    end
  end

  private

  def set_game
    @game = Game.find_by(id: params[:id])
  end

  def validations
    # Check if the game exists
    unless @game
      render_error('Game does not exist', :not_found)
      return
    end

    @token = request.headers['Authorization']

    # Check if the token was provided
    unless @token
      render_error('Token was not provided', :unauthorized)
      return
    end

    # Check if the provided token matches token_1 or token_2
    unless [@game.token_1, @game.token_2].include?(@token)
      render_error('Wrong token', :unauthorized)
      return
    end
  end

  def render_error(message, status)
    render json: { error: message }, status: status
  end

  def render_game_status
    render json: { board_state: @game.board_state, game_status: @game.game_status, player_1_pieces: @game.player_1_pieces, player_2_pieces: @game.player_2_pieces }, status: :ok
  end

  def game_in_progress?
    @game.game_status == 'Player_1 turn' || @game.game_status == 'Player_2 turn'
  end

  def tile_exists?(row, column)
    row.between?(0, 7) && column.between?(0, 7)
  end

  def general_turn_validation(token_1, turn_1, token_2, turn_2)
    (@token == token_1 && @game.game_status == turn_1) || (@token == token_2 && @game.game_status == turn_2)
  end

  def piece_validation(token, tile, regular_piece, king_piece)
    (token == @token && (tile == regular_piece || tile == king_piece))
  end
end
