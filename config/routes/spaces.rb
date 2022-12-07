Rails.application.routes.draw do
  get  'spaces',              to: 'spaces#index',   as: 'spaces'
  get  '-/:code',             to: 'spaces#show',    as: 'space'
  get  'spaces/create',       to: 'spaces#new',     as: 'new_space'
  post 'spaces/create',       to: 'spaces#create',  as: 'create_space'
  get  'spaces/:code/update', to: 'spaces#edit',    as: 'edit_space'
  post 'spaces/:code/update', to: 'spaces#update',  as: 'update_space'
  get  'spaces/:code/delete', to: 'spaces#delete',  as: 'delete_space'
  post 'spaces/:code/delete', to: 'spaces#destroy', as: 'destroy_space'
end
