class Infomation < ApplicationRecord
  belongs_to :target_user, class_name: 'User', optional: true
  enum target: { All: 1, User: 2 }
end
