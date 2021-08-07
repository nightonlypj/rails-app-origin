Rails.application.routes.draw do
  # mount_devise_token_auth_for 'User', at: 'auth'
  # お知らせ
  resources :infomations, only: %i[index show]

  # 管理ユーザー
  devise_for :admin_users, skip: :all
  devise_scope :admin_user do
    get    'admin/sign_in',       to: 'admin_users/sessions#new',     as: 'new_admin_user_session'
    post   'admin/sign_in',       to: 'admin_users/sessions#create',  as: 'create_admin_user_session'
    get    'admin/sign_out',      to: 'admin_users/sessions#destroy', as: 'destroy_admin_user_session'
    delete 'admin/sign_out',      to: 'admin_users/sessions#destroy', as: nil
    get    'admin/unlock/new',    to: 'admin_users/unlocks#new',      as: 'new_admin_user_unlock'
    post   'admin/unlock/new',    to: 'admin_users/unlocks#create',   as: 'create_admin_user_unlock'
    get    'admin/unlock',        to: 'admin_users/unlocks#show',     as: 'admin_user_unlock'
    get    'admin/password/new',  to: 'admin_users/passwords#new',    as: 'new_admin_user_password'
    post   'admin/password/new',  to: 'admin_users/passwords#create', as: 'create_admin_user_password'
    get    'admin/password',      to: 'admin_users/passwords#edit',   as: 'edit_admin_user_password'
    put    'admin/password',      to: 'admin_users/passwords#update', as: 'update_admin_user_password'
    patch  'admin/password',      to: 'admin_users/passwords#update', as: nil
  end

  # ユーザー
  devise_for :users, skip: :all
  devise_scope :user do
    get    'users/sign_up',          to: 'users/registrations#new',           as: 'new_user_registration'
    post   'users/sign_up',          to: 'users/registrations#create',        as: 'create_user_registration'
    get    'users/edit',             to: 'users/registrations#edit',          as: 'edit_user_registration'
    put    'users/edit',             to: 'users/registrations#update',        as: 'update_user_registration'
    patch  'users/edit',             to: 'users/registrations#update',        as: nil
    get    'users/image',            to: 'users/registrations#edit',          as: nil
    put    'users/image',            to: 'users/registrations#image_update',  as: 'update_user_image_registration'
    patch  'users/image',            to: 'users/registrations#image_update',  as: nil
    delete 'users/image',            to: 'users/registrations#image_destroy', as: 'delete_user_image_registration'
    get    'users/delete',           to: 'users/registrations#delete',        as: 'delete_user_registration'
    delete 'users/delete',           to: 'users/registrations#destroy',       as: 'destroy_user_registration'
    get    'users/undo_delete',      to: 'users/registrations#undo_delete',   as: 'delete_undo_user_registration'
    delete 'users/undo_delete',      to: 'users/registrations#undo_destroy',  as: 'destroy_undo_user_registration'
    get    'users/confirmation/new', to: 'users/confirmations#new',           as: 'new_user_confirmation'
    post   'users/confirmation/new', to: 'users/confirmations#create',        as: 'create_user_confirmation'
    get    'users/confirmation',     to: 'users/confirmations#show',          as: 'user_confirmation'
    get    'users/sign_in',          to: 'users/sessions#new',                as: 'new_user_session'
    post   'users/sign_in',          to: 'users/sessions#create',             as: 'create_user_session'
    get    'users/sign_out',         to: 'users/sessions#destroy',            as: 'destroy_user_session'
    delete 'users/sign_out',         to: 'users/sessions#destroy',            as: nil
    get    'users/unlock/new',       to: 'users/unlocks#new',                 as: 'new_user_unlock'
    post   'users/unlock/new',       to: 'users/unlocks#create',              as: 'create_user_unlock'
    get    'users/unlock',           to: 'users/unlocks#show',                as: 'user_unlock'
    get    'users/password/new',     to: 'users/passwords#new',               as: 'new_user_password'
    post   'users/password/new',     to: 'users/passwords#create',            as: 'create_user_password'
    get    'users/password',         to: 'users/passwords#edit',              as: 'edit_user_password'
    put    'users/password',         to: 'users/passwords#update',            as: 'update_user_password'
    patch  'users/password',         to: 'users/passwords#update',            as: nil
  end

  # トップ
  root 'top#index'

  # 管理・デバッグ用
  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'
  mount LetterOpenerWeb::Engine => '/letter_opener' if Rails.env.development?
end
