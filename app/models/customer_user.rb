class CustomerUser < ApplicationRecord
  belongs_to :customer
  belongs_to :user
  enum power: { Owner: 1, Admin: 2, Member: 3 }
end
