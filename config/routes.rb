Rails.application.routes.draw do

  scope :api, format: false, defaults: { format: :json } do
    get 'changes_webhook', to: 'change#update'

    resources :entries, only: %i(index create), path: 'marketentries'
    resources :categories, only: %i(index)
    resources :chapters, only: %i(index show)
  end

end
