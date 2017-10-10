Rails.application.routes.draw do

  scope :api do
    get 'changes_webhook', to: 'change#update'

    resources :entries, only: %i(index create), path: 'marketentries'
  end

end
