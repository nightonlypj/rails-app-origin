Rails.application.routes.draw do
  # お知らせ
  resources :infomations, only: %i[index show]

  # 管理ユーザー
  devise_for :admin_users, skip: :all
  devise_scope :admin_user do
    get    'admin_users/sign_in',       to: 'admin_users/sessions#new',     as: 'new_admin_user_session'
    post   'admin_users/sign_in',       to: 'admin_users/sessions#create',  as: 'admin_user_session'
    delete 'admin_users/sign_out',      to: 'admin_users/sessions#destroy', as: 'destroy_admin_user_session'
    get    'admin_users/sign_out',      to: 'admin_users/sessions#destroy'
    get    'admin_users/unlock/new',    to: 'admin_users/unlocks#new',      as: 'new_admin_user_unlock'
    post   'admin_users/unlock',        to: 'admin_users/unlocks#create',   as: nil
    get    'admin_users/unlock',        to: 'admin_users/unlocks#show',     as: 'admin_user_unlock'
    get    'admin_users/password/new',  to: 'admin_users/passwords#new',    as: 'new_admin_user_password'
    post   'admin_users/password',      to: 'admin_users/passwords#create', as: nil
    get    'admin_users/password/edit', to: 'admin_users/passwords#edit',   as: 'edit_admin_user_password'
    put    'admin_users/password',      to: 'admin_users/passwords#update', as: 'admin_user_password'
    patch  'admin_users/password',      to: 'admin_users/passwords#update', as: nil
  end

  # ユーザー
  devise_for :users, skip: :all
  devise_scope :user do
    get    'users/sign_up',          to: 'users/registrations#new',     as: 'new_user_registration'
    post   'users',                  to: 'users/registrations#create',  as: nil
    get    'users/edit',             to: 'users/registrations#edit',    as: 'edit_user_registration'
    put    'users',                  to: 'users/registrations#update',  as: 'user_registration'
    patch  'users',                  to: 'users/registrations#update',  as: nil
    put    'users/image',            to: 'users/registrations#image_update'
    delete 'users/image',            to: 'users/registrations#image_destroy'
    get    'users/delete',           to: 'users/registrations#delete'
    delete 'users',                  to: 'users/registrations#destroy', as: nil
    get    'users/undo_delete',      to: 'users/registrations#undo_delete'
    delete 'users/undo_delete',      to: 'users/registrations#undo_destroy'
    get    'users/cancel',           to: 'users/registrations#cancel',  as: 'cancel_user_registration'
    get    'users/confirmation/new', to: 'users/confirmations#new',     as: 'new_user_confirmation'
    post   'users/confirmation',     to: 'users/confirmations#create',  as: nil
    get    'users/confirmation',     to: 'users/confirmations#show',    as: 'user_confirmation'
    get    'users/sign_in',          to: 'users/sessions#new',          as: 'new_user_session'
    post   'users/sign_in',          to: 'users/sessions#create',       as: 'user_session'
    delete 'users/sign_out',         to: 'users/sessions#destroy',      as: 'destroy_user_session'
    get    'users/sign_out',         to: 'users/sessions#destroy'
    get    'users/unlock/new',       to: 'users/unlocks#new',           as: 'new_user_unlock'
    post   'users/unlock',           to: 'users/unlocks#create',        as: nil
    get    'users/unlock',           to: 'users/unlocks#show',          as: 'user_unlock'
    get    'users/password/new',     to: 'users/passwords#new',         as: 'new_user_password'
    post   'users/password',         to: 'users/passwords#create',      as: nil
    get    'users/password/edit',    to: 'users/passwords#edit',        as: 'edit_user_password'
    put    'users/password',         to: 'users/passwords#update',      as: 'user_password'
    patch  'users/password',         to: 'users/passwords#update',      as: nil
  end

  # トップ
  root 'top#index'

  # 管理・デバッグ用
  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'
  mount LetterOpenerWeb::Engine => '/letter_opener' if Rails.env.development?
end
