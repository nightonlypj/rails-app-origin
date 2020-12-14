Rails.application.routes.draw do
  # スペース
  get   'spaces',      to: 'spaces#index', as: 'spaces'
  post  'spaces',      to: 'spaces#create'
  get   'spaces/new',  to: 'spaces#new',    as: 'new_space'
  get   'spaces/edit', to: 'spaces#edit',   as: 'edit_space'
  patch 'spaces',      to: 'spaces#update', as: 'space'
  put   'spaces',      to: 'spaces#update'

  # メンバー
  resources :customer_users, only: %i[index new create edit update destroy]
  get 'customer_users/:id/delete', to: 'customer_users#delete'

  # 所属（顧客）
  resources :customers, only: %i[index]

  # 管理ユーザー
  devise_for :admin_users, controllers: {
    registrations: 'admin_users/registrations',
    confirmations: 'admin_users/confirmations',
    sessions: 'admin_users/sessions',
    unlocks: 'admin_users/unlocks',
    passwords: 'admin_users/passwords'
  }

  # ユーザー
  devise_for :users, controllers: {
    registrations: 'users/registrations',
    confirmations: 'users/confirmations',
    sessions: 'users/sessions',
    unlocks: 'users/unlocks',
    passwords: 'users/passwords'
  }
  devise_scope :user do
    put    'users/image',       to: 'users/registrations#image_update'
    delete 'users/image',       to: 'users/registrations#image_destroy'
    get    'users/delete',      to: 'users/registrations#delete'
    get    'users/undo_delete', to: 'users/registrations#undo_delete'
    delete 'users/undo_delete', to: 'users/registrations#undo_destroy'
  end

  # トップ
  root 'top#index'

  # 管理・デバッグ用
  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'
  mount LetterOpenerWeb::Engine => '/letter_opener' if Rails.env.development?
end
