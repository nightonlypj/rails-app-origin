class Customer < ApplicationRecord
  has_many :member

  validates :code, presence: true
  validates :code, length: { in: Settings['customer_code_minimum']..Settings['customer_code_maximum'] }, if: proc { |customer| customer.code.present? }
  validates :code, format: { with: /\A[a-z\d]*\z/ }, if: proc { |customer| customer.code.present? }
  validates :code, uniqueness: true
  validates :name, presence: true
  validates :name, length: { in: Settings['customer_name_minimum']..Settings['customer_name_maximum'] }, if: proc { |customer| customer.name.present? }
end
