Rails.application.routes.draw do
  resources :infomations, only: %i[index show]
  draw :admin
  draw :users
  root 'top#index'
  mount LetterOpenerWeb::Engine => '/letter_opener' if Rails.env.development?
end
