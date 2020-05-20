class Space < ApplicationRecord
  has_paper_trail

  validates :subdomain, presence: true
  validates :subdomain, length: { in: 1..32 }
  validates :subdomain, format: { with: /\A[a-z0-9][a-z0-9\d\-]*\z/ }
  validates :subdomain, uniqueness: true
  validates :name, presence: true
  validates :name, length: { maximum: 32 }
end
