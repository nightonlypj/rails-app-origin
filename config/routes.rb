Rails.application.routes.draw do
  # スペース
  get    'spaces',        to: 'spaces#index',        as: 'spaces'
  get    'spaces/public', to: 'spaces#index_public', as: 'public_spaces'
  get    'spaces/new',    to: 'spaces#new',          as: 'new_space'
  post   'spaces/new',    to: 'spaces#create',       as: 'create_space'
  get    'spaces/edit',   to: 'spaces#edit',         as: 'edit_space'
  put    'spaces/edit',   to: 'spaces#update',       as: 'update_space'
  patch  'spaces/edit',   to: 'spaces#update',       as: nil
  get    'spaces/image',  to: 'spaces#edit',         as: nil
  put    'spaces/image',  to: 'spaces#image_update', as: 'update_space_image'
  patch  'spaces/image',  to: 'spaces#image_update', as: nil
  delete 'spaces/image',  to: 'spaces#image_destroy', as: 'delete_space_image'

  # メンバー
  get    'members/:customer_code',                   to: 'members#index', as: 'members'
  post   'members/:customer_code',                   to: 'members#create'
  get    'members/:customer_code/new',               to: 'members#new',    as: 'new_member'
  get    'members/:customer_code/:user_code/edit',   to: 'members#edit',   as: 'edit_member'
  patch  'members/:customer_code/:user_code',        to: 'members#update', as: 'member'
  put    'members/:customer_code/:user_code',        to: 'members#update'
  get    'members/:customer_code/:user_code/delete', to: 'members#delete', as: 'delete_member'
  delete 'members/:customer_code/:user_code',        to: 'members#destroy'

  # メンバー登録
  get    'registration/sign_up', to: 'registration#new',    as: 'registration_sign_up' # Tips: NG(new_registration)
  post   'registration/sign_up', to: 'registration#create', as: nil

  # 顧客（所属）
  get 'customers',                to: 'customers#index', as: 'customers'
  get 'customers/:customer_code', to: 'customers#show',  as: 'customer'

  # お知らせ
  resources :infomations, only: %i[index show]

  # 管理ユーザー
  devise_for :admin_users, controllers: {
    sessions: 'admin_users/sessions',
    unlocks: 'admin_users/unlocks',
    passwords: 'admin_users/passwords'
  }
  devise_scope :admin_user do
    get 'admin_users/sign_out', to: 'admin_users/sessions#destroy'
  end

  # ユーザー
  devise_for :users, controllers: {
    registrations: 'users/registrations',
    confirmations: 'users/confirmations',
    sessions: 'users/sessions',
    unlocks: 'users/unlocks',
    passwords: 'users/passwords'
  }
  devise_scope :user do
    get    'users/sign_out',    to: 'users/sessions#destroy'
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
