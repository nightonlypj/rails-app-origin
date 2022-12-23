Rails.application.routes.draw do
  get  'spaces',                   to: 'spaces#index',        as: 'spaces'
  get  '-/:code',                  to: 'spaces#show',         as: 'space'
  get  'spaces/create',            to: 'spaces#new',          as: 'new_space'
  post 'spaces/create',            to: 'spaces#create',       as: 'create_space'
  get  'spaces/update/:code',      to: 'spaces#edit',         as: 'edit_space'
  post 'spaces/update/:code',      to: 'spaces#update',       as: 'update_space'
  get  'spaces/delete/:code',      to: 'spaces#delete',       as: 'delete_space'
  post 'spaces/delete/:code',      to: 'spaces#destroy',      as: 'destroy_space'
  get  'spaces/undo_delete/:code', to: 'spaces#undo_delete',  as: 'delete_undo_space'
  post 'spaces/undo_delete/:code', to: 'spaces#undo_destroy', as: 'undo_destroy_space'
end
