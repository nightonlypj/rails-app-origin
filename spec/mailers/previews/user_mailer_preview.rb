# Preview all emails at http://localhost:3000/rails/mailers/user_mailer
class UserMailerPreview < ActionMailer::Preview
  # アカウント削除受け付けのお知らせ
  def destroy_reserved(undo_delete_url = nil)
    user = FactoryBot.build_stubbed(:user, :destroy_reserved)
    UserMailer.with(user:, undo_delete_url:).destroy_reserved
  end

  def destroy_reserved_auth
    undo_delete_url = Faker::Internet.url(scheme: 'https')
    destroy_reserved(undo_delete_url)
  end

  # アカウント削除取り消し完了のお知らせ
  def undo_destroy_reserved
    user = FactoryBot.build_stubbed(:user)
    UserMailer.with(user:).undo_destroy_reserved
  end

  # アカウント削除完了のお知らせ
  def destroy_completed
    user = FactoryBot.build_stubbed(:user, :destroy_reserved)
    UserMailer.with(user:).destroy_completed
  end
end
