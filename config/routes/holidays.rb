Rails.application.routes.draw do
  get 'holidays', to: 'holidays#index', as: 'holidays'
end
