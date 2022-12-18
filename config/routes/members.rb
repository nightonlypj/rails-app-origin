Rails.application.routes.draw do
  get  'members/:code',                   to: 'members#index',   as: 'members'
  get  'members/:code/detail/:user_code', to: 'members#show',    as: 'member'
  get  'members/:code/create',            to: 'members#new',     as: 'new_member'
  post 'members/:code/create',            to: 'members#create',  as: 'create_member'
  get  'members/:code/result',            to: 'members#result',  as: 'result_member'
  get  'members/:code/update/:user_code', to: 'members#edit',    as: 'edit_member'
  post 'members/:code/update/:user_code', to: 'members#update',  as: 'update_member'
  get  'members/:code/delete',            to: 'members#index',   as: nil # NOTE: URL直アクセス対応
  post 'members/:code/delete',            to: 'members#destroy', as: 'destroy_member'
end
