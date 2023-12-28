Rails.application.routes.draw do
  resources :games, only: [:create, :show]
  get '/games/:id/movements/:row/:column', to: 'games#movements'
  patch '/games/:id/move/:row/:column/to/:new_row/:new_column', to: 'games#move'
end
