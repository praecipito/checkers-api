Rails.application.routes.draw do
  post '/games', to: 'games#create'
  get '/games/:id', to: 'games#show', as: 'game'
end
