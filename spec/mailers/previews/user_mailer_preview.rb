# Preview all emails at http://localhost:3000/rails/mailers/user_mailer
class UserMailerPreview < ActionMailer::Preview
  # アカウント削除受け付けのお知らせ
  def destroy_reserved
    user = FactoryBot.build_stubbed(:user, destroy_schedule_at: Time.current + Settings['destroy_schedule_days'].days)
    UserMailer.with(user: user).destroy_reserved
  end

  # アカウント削除取り消し完了のお知らせ
  def undo_destroy_reserved
    user = FactoryBot.build_stubbed(:user)
    UserMailer.with(user: user).undo_destroy_reserved
  end

  # アカウント削除完了のお知らせ
  def destroy_completed
    user = FactoryBot.build_stubbed(:user)
    UserMailer.with(user: user).destroy_completed
  end
end
