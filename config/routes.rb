Rails.application.routes.draw do
  resources :games, only: [:create, :show]
  get '/games/:id/moves/:row/:column', to: 'games#moves'
  patch '/games/:id/move/:row/:column/to/:new_row/:new_column', to: 'games#move'
end
