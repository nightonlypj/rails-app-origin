class Holiday < ApplicationRecord
  validates :date, presence: true
  validates :date, uniqueness: { case_sensitive: true }, allow_blank: true
  validates :name, presence: true
end
