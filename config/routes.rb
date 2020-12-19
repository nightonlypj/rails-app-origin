Rails.application.routes.draw do
  # スペース
  get   'spaces',      to: 'spaces#index', as: 'spaces'
  post  'spaces',      to: 'spaces#create'
  get   'spaces/new',  to: 'spaces#new',    as: 'new_space'
  get   'spaces/edit', to: 'spaces#edit',   as: 'edit_space'
  patch 'spaces',      to: 'spaces#update', as: 'space'
  put   'spaces',      to: 'spaces#update'

  # メンバー
  get    'customer_users/:customer_code',            to: 'customer_users#index', as: 'customer_users'
  post   'customer_users/:customer_code',            to: 'customer_users#create'
  get    'customer_users/:customer_code/new',        to: 'customer_users#new',    as: 'new_customer_user'
  get    'customer_users/:customer_code/:id/edit',   to: 'customer_users#edit',   as: 'edit_customer_user'
  patch  'customer_users/:customer_code/:id',        to: 'customer_users#update', as: 'customer_user'
  put    'customer_users/:customer_code/:id',        to: 'customer_users#update'
  get    'customer_users/:customer_code/:id/delete', to: 'customer_users#delete', as: 'delete_customer_user'
  delete 'customer_users/:customer_code/:id',        to: 'customer_users#destroy'

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
