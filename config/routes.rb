Rails.application.routes.draw do

  resources :entries, only: :create

  get '/api/marketentries', to: 'entries#index'

end
