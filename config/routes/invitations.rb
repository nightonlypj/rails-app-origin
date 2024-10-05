Rails.application.routes.draw do
  scope '(:locale)', locale: /#{I18n.available_locales.map(&:to_s).join('|')}/ do
    get  'invitations/:space_code',              to: 'invitations#index',   as: 'invitations'
    get  'invitations/:space_code/detail/:code', to: 'invitations#show',    as: 'invitation'
    get  'invitations/:space_code/create',       to: 'invitations#new',     as: 'new_invitation'
    post 'invitations/:space_code/create',       to: 'invitations#create',  as: 'create_invitation'
    get  'invitations/:space_code/update/:code', to: 'invitations#edit',    as: 'edit_invitation'
    post 'invitations/:space_code/update/:code', to: 'invitations#update',  as: 'update_invitation'
  end
end
