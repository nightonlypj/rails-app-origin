# Preview all emails at http://localhost:3000/rails/mailers/admin_user_devise_mailer
class AdminUserDeviseMailerPreview < ActionMailer::Preview
  # パスワード再設定方法のお知らせ
  def reset_password_instructions
    admin_user = FactoryBot.build_stubbed(:admin_user)
    DeviseMailer.reset_password_instructions(admin_user, token)
  end

  # アカウントロックのお知らせ
  def unlock_instructions
    admin_user = FactoryBot.build_stubbed(:admin_user_locked)
    DeviseMailer.unlock_instructions(admin_user, token)
  end

  # パスワード変更完了のお知らせ
  def password_change
    admin_user = FactoryBot.build_stubbed(:admin_user)
    DeviseMailer.password_change(admin_user)
  end

  private

  def token
    Faker::Internet.password(min_length: 20, max_length: 20)
  end
end
