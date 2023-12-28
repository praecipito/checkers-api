# Checkers Game API

This is a simple JSON REST API for playing checkers using Ruby on Rails 7.0.8 and Rails 3.1.2. The API allows two players to engage in a game of checkers.

## Setup

- **Clone the Repository:**
  ```
  git clone <repository_url>
  ```

- **Installation:**
  ```
  bundle install
  ```

- **Database Setup:**
  ```
  rails db:create
  rails db:migrate
  ```

- **Run the Server:**
  ```
  rails server
  ```

## Endpoints

1. **Create a New Game**
   - **Endpoint:** `POST /games`
   - **Description:** Creates a new checkers game.
   - **Parameters:** None required.
   - **Response:** Returns `game_id`, `token_1`, and `token_2` for the new game.

2. **Show Game State**
   - **Endpoint:** `GET /games/:id`
   - **Description:** Displays the game state for a given game ID.
   - **Parameters:**
     - `id`: Game ID
     - *Authorization Header:* Token (`token_1` for player_1 or `token_2` for player_2)
   - **Response:** Returns `board_state` and `game_status` for the specified game.

3. **Show Possible Piece Movements**
   - **Endpoint:** `GET /games/:id/movements/:row/:column`
   - **Description:** Show possible moves to the specified piece.
   - **Parameters:**
     - `id`: Game ID
     - `row`, `column`: Position of the piece
     - *Authorization Header:* Token (`token_1` for player_1 or `token_2` for player_2)
   - **Response:** Returns `tile_requested` and `possible_moves` to the specified piece.

4. **Move Piece and Update Board**
   - **Endpoint:** `PATCH /games/:id/move/:row/:column/to/:new_row/:new_column`
   - **Description:** Moves a piece on the board.
   - **Parameters:**
     - `id`: Game ID
     - `row`, `column`: Initial position of the piece
     - `new_row`, `new_column`: New position for the piece
     - *Authorization Header:* Token (`token_1` for player_1 or `token_2` for player_2)
   - **Response:** Provides details about the requested move.
