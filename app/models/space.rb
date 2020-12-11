class Space < ApplicationRecord
  belongs_to :customer

  validates :subdomain, presence: true
  validates :subdomain, length: { in: Settings['subdomain_minimum']..Settings['subdomain_maximum'] }, if: proc { |space| space.subdomain.present? }
  validates :subdomain, format: { with: /\A[a-z0-9][a-z0-9\d\-]*\z/ }, if: proc { |space| space.subdomain.present? }
  validates :subdomain, uniqueness: true
  validates :name, presence: true
  validates :name, length: { in: Settings['space_name_minimum']..Settings['space_name_maximum'] }, if: proc { |space| space.name.present? }
end
