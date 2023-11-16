Rails.application.routes.draw do
  draw :holidays
  draw :infomations
  draw :admin
  draw :users
  root 'top#index'
  # :nocov:
  mount LetterOpenerWeb::Engine => '/letter_opener' if Rails.env.development?
  # :nocov:
end
