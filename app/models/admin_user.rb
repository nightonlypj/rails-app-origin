class AdminUser < ApplicationRecord
  include UsersConcern

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable,
         :recoverable, :validatable,
         :lockable, :timeoutable, :trackable

  validates :name, presence: true
  validates :name, length: { in: Settings['user_name_minimum']..Settings['user_name_maximum'] }, if: proc { |admin_user| admin_user.name.present? }
end
