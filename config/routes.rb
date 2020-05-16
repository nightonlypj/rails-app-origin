Rails.application.routes.draw do
  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'
  devise_for :admin_users, controllers: {
    sessions: 'admin_users/sessions'
  }
  devise_for :users, controllers: {
    sessions: 'users/sessions'
  }
  root 'top#index'
end
