Rails.application.routes.draw do

  scope :api do
    resources :entries, only: %i(index create), path: 'marketentries'
  end

end
