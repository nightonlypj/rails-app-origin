Rails.application.routes.draw do
  scope '(:locale)', locale: /#{I18n.available_locales.join('|')}/ do
    get 'infomations',           to: 'infomations#index',     as: 'infomations'
    get 'infomations/important', to: 'infomations#important', as: 'important_infomations'
    get 'infomations/:id',       to: 'infomations#show',      as: 'infomation'
  end
end
