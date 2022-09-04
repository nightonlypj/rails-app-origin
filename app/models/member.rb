class Member < ApplicationRecord
  belongs_to :space
  belongs_to :user
  belongs_to :invitation_user, class_name: 'User', optional: true

  # 権限
  enum power: {
    Admin: 1, # 管理者
    Writer: 2, # 投稿者
    Reader: 3 # 閲覧者
  }, _prefix: true
end
