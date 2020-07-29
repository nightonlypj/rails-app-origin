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
  end
  root 'top#index'
end
