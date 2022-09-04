class Space < ApplicationRecord
  belongs_to :create_user,      class_name: 'User'
  belongs_to :last_update_user, class_name: 'User', optional: true
  has_many :member, dependent: :destroy
end
