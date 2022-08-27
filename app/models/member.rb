class Member < ApplicationRecord
  belongs_to :space
  belongs_to :user
end
