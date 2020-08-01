class User < ApplicationRecord
  has_paper_trail
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :lockable, :timeoutable, :trackable

  # 削除予約（削除予約・予定日時セット）
  def delete_reserved
    update!(delete_reserved_at: Time.current, delete_schedule_at: Time.current + Settings['delete_schedule_days'].days)
  end
end
