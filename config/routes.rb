Rails.application.routes.draw do
  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'
  devise_for :admin_users, controllers: {
    registrations: 'admin_users/registrations',
    confirmations: 'admin_users/confirmations',
    sessions: 'admin_users/sessions',
    unlocks: 'admin_users/unlocks',
    passwords: 'admin_users/passwords'
  }
  devise_for :users, controllers: {
    registrations: 'users/registrations',
    confirmations: 'users/confirmations',
    sessions: 'users/sessions',
    unlocks: 'users/unlocks',
    passwords: 'users/passwords'
  }
  devise_scope :user do
    get 'users/delete', to: 'users/registrations#delete'
    get 'users/undo_delete', to: 'users/registrations#undo_delete'
    put 'users/undo_destroy', to: 'users/registrations#undo_destroy'
  end
  root 'top#index'
  mount LetterOpenerWeb::Engine, at: '/letter_opener' if Rails.env.development?
end
