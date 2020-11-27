class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :lockable, :timeoutable, :trackable

  # 削除予約済みか返却
  def destroy_reserved?
    destroy_schedule_at.present?
  end

  # 削除予約
  def set_destroy_reserve
    update!(destroy_requested_at: Time.current,
            destroy_schedule_at: Time.current + Settings['destroy_schedule_days'].days)
  end

  # 削除予約取り消し
  def set_undo_destroy_reserve
    update!(destroy_requested_at: nil,
            destroy_schedule_at: nil)
  end
end
