Rails.application.routes.draw do
  scope '(:locale)', locale: /#{I18n.available_locales.map(&:to_s).join('|')}/ do
    get 'holidays', to: 'holidays#index', as: 'holidays'
  end
end
