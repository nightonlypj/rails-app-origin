Rails.application.routes.draw do
  scope '(:locale)', locale: /#{I18n.available_locales.map(&:to_s).join('|')}/ do
    devise_for :admin_users, skip: :all
    devise_scope :admin_user do
      get    'admin/sign_in',        to: 'admin_users/sessions#new',     as: 'new_admin_user_session'
      post   'admin/sign_in',        to: 'admin_users/sessions#create',  as: 'create_admin_user_session'
      get    'admin/sign_out',       to: 'admin_users/sessions#destroy', as: nil # NOTE: URL直アクセス対応
      post   'admin/sign_out',       to: 'admin_users/sessions#destroy', as: 'destroy_admin_user_session'
      delete 'admin/sign_out',       to: 'admin_users/sessions#destroy', as: nil # NOTE: RailsAdmin用
      get    'admin/unlock/resend',  to: 'admin_users/unlocks#new',      as: 'new_admin_user_unlock'
      post   'admin/unlock/resend',  to: 'admin_users/unlocks#create',   as: 'create_admin_user_unlock'
      get    'admin/unlock',         to: 'admin_users/unlocks#show',     as: 'admin_user_unlock'
      get    'admin/password/reset', to: 'admin_users/passwords#new',    as: 'new_admin_user_password'
      post   'admin/password/reset', to: 'admin_users/passwords#create', as: 'create_admin_user_password'
      get    'admin/password',       to: 'admin_users/passwords#edit',   as: 'edit_admin_user_password'
      put    'admin/password',       to: 'admin_users/passwords#update', as: 'update_admin_user_password'
    end
    mount RailsAdmin::Engine => '/admin', as: 'rails_admin'
  end
end
