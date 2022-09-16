Rails.application.routes.draw do
  get  'members/:code',        to: 'members#index',   as: 'members'
  get  'members/:code/create', to: 'members#new',     as: 'new_member'
  post 'members/:code/create', to: 'members#create',  as: 'create_member'
  get  'members/:code/update', to: 'members#edit',    as: 'edit_member'
  post 'members/:code/update', to: 'members#update',  as: 'update_member'
  get  'members/:code/delete', to: 'members#delete',  as: 'delete_member'
  post 'members/:code/delete', to: 'members#destroy', as: 'destroy_member'
end
