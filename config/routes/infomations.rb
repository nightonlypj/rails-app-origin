Rails.application.routes.draw do
  get 'infomations',           to: 'infomations#index',     as: 'infomations'
  get 'infomations/important', to: 'infomations#important', as: 'important_infomations'
  get 'infomations/:id',       to: 'infomations#show',      as: 'infomation'
end
