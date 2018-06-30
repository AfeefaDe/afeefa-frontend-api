Rails.application.routes.draw do

  scope :api, format: false, defaults: { format: :json } do
    get 'changes_webhook', to: 'change#update'

    post ':type/:id/contact', to: 'entries#contact_entry'
    post ':type/:id/feedback', to: 'entries#feedback_entry'

    resources :entries, only: %i(index create)
    resources :translations, only: %i(index)
    resources :facets, only: %i(index)
    resources :navigation, only: %i(index)

    resources :chapters, only: %i(index show)
  end

end
