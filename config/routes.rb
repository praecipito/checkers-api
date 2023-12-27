Rails.application.routes.draw do
  resources :games, only: [:create, :show]
  get '/games/:id/moves/:row/:column', to: 'games#moves'
end
