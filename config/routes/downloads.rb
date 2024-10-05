Rails.application.routes.draw do
  scope '(:locale)', locale: /#{I18n.available_locales.map(&:to_s).join('|')}/ do
    get  'downloads',          to: 'downloads#index',  as: 'downloads'
    get  'downloads/file/:id', to: 'downloads#file',   as: 'file_download'
    get  'downloads/create',   to: 'downloads#new',    as: 'new_download'
    post 'downloads/create',   to: 'downloads#create', as: 'create_download'
  end
end
