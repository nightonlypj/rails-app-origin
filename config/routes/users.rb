Rails.application.routes.draw do
  devise_for :users, skip: :all
  devise_scope :user do
    get    'users/sign_up',          to: 'users/registrations#new',           as: 'new_user_registration'
    post   'users/sign_up',          to: 'users/registrations#create',        as: 'create_user_registration'
    get    'users/edit',             to: 'users/registrations#edit',          as: 'edit_user_registration'
    put    'users/edit',             to: 'users/registrations#update',        as: 'update_user_registration'
    patch  'users/edit',             to: 'users/registrations#update',        as: nil
    get    'users/image',            to: 'users/registrations#edit',          as: nil
    get    'users/image/update',     to: 'users/registrations#edit',          as: nil
    post   'users/image/update',     to: 'users/registrations#image_update',  as: 'update_user_image_registration'
    get    'users/image/destroy',    to: 'users/registrations#edit',          as: nil
    delete 'users/image/destroy',    to: 'users/registrations#image_destroy', as: 'delete_user_image_registration'
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

    # Devise Token Auth
    defaults format: :json do
      post   'users/auth/sign_up',         to: 'users/auth/registrations#create',             as: 'create_user_auth_registration'
      get    'users/auth/show',            to: 'users/auth/registrations#show',               as: 'show_user_auth_registration'
      put    'users/auth/update',          to: 'users/auth/registrations#update',             as: 'update_user_auth_registration'
      patch  'users/auth/update',          to: 'users/auth/registrations#update',             as: nil
      post   'users/auth/image/update',    to: 'users/auth/registrations#image_update',       as: 'update_user_auth_image_registration'
      delete 'users/auth/image/delete',    to: 'users/auth/registrations#image_destroy',      as: 'delete_user_auth_image_registration'
      delete 'users/auth/delete',          to: 'users/auth/registrations#destroy',            as: 'destroy_user_auth_registration'
      delete 'users/auth/undo_delete',     to: 'users/auth/registrations#undo_destroy',       as: 'destroy_undo_user_auth_registration'
      post   'users/auth/confirmation',    to: 'users/auth/confirmations#create',             as: 'create_user_auth_confirmation'
      post   'users/auth/sign_in',         to: 'users/auth/sessions#create',                  as: 'create_user_auth_session'
      delete 'users/auth/sign_out',        to: 'users/auth/sessions#destroy',                 as: 'destroy_user_auth_session'
      post   'users/auth/unlock',          to: 'users/auth/unlocks#create',                   as: 'create_user_auth_unlock'
      post   'users/auth/password',        to: 'users/auth/passwords#create',                 as: 'create_user_auth_password'
      put    'users/auth/password/update', to: 'users/auth/passwords#update',                 as: 'update_user_auth_password'
      patch  'users/auth/password/update', to: 'users/auth/passwords#update',                 as: nil
      get    'users/auth/validate_token',  to: 'users/auth/token_validations#validate_token', as: 'user_auth_validate_token'
    end
    get 'users/auth/confirmation', to: 'users/auth/confirmations#show', as: 'user_auth_confirmation'
    get 'users/auth/unlock',       to: 'users/auth/unlocks#show',       as: 'user_auth_unlock'
    get 'users/auth/password',     to: 'users/auth/passwords#edit',     as: 'edit_user_auth_password'
  end
end
