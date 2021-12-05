Rails.application.routes.draw do
  defaults format: :json do
    get 'infomations/important', to: 'infomations#important', as: 'important_infomations'
  end
  get 'infomations',     to: 'infomations#index', as: 'infomations'
  get 'infomations/:id', to: 'infomations#show',  as: 'infomation'
end
