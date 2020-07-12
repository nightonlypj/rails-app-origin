Rails.application.routes.draw do
  get 'spaces', to: 'spaces#index'
  post 'spaces/create', to: 'spaces#create', as: 'create_space'
  get 'spaces/new', to: 'spaces#new', as: 'new_space'
  get 'spaces/edit', to: 'spaces#edit', as: 'edit_space'
  patch 'spaces/update', to: 'spaces#update', as: 'update_space'
  put 'spaces/update', to: 'spaces#update', as: nil

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
  root 'top#index'
end
