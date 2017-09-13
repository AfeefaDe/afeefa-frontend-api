Rails.application.routes.draw do

  namespace :api do
    resources :entries, only: %i(index create), path: 'marketentries'
  end

end
