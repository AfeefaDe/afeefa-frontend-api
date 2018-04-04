Rails.application.routes.draw do

  scope :api, format: false, defaults: { format: :json } do
    get 'changes_webhook', to: 'change#update'

    post ':type/:id/contact', to: 'entries#contact_entry'
    post ':type/:id/feedback', to: 'entries#feedback_entry'
    post 'general_feedback', to: 'feedbacks#general_feedback'

    resources :entries, only: %i(index create), path: 'marketentries'
    resources :categories, only: %i(index)
    resources :chapters, only: %i(index show)
  end

end
