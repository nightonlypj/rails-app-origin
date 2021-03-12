class Customer < ApplicationRecord
  attr_accessor :create_flag

  has_many :member
  has_many :space

  validates :create_flag, inclusion: { in: [nil, 'true', 'false'] }
  validates :code, presence: true, if: proc { |customer| [nil, 'true', 'false'].include?(customer.create_flag) }
  validates :code, uniqueness: { case_sensitive: true },
                   if: proc { |customer| [nil, 'true'].include?(customer.create_flag) && customer.code.present? }
  validates :name, presence: true, if: proc { |customer| [nil, 'true'].include?(customer.create_flag) }
  validates :name, length: { in: Settings['customer_name_minimum']..Settings['customer_name_maximum'] },
                   if: proc { |customer| [nil, 'true'].include?(customer.create_flag) && customer.name.present? }
end
