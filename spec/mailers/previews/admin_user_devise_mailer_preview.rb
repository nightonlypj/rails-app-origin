# Preview all emails at http://localhost:3000/rails/mailers/admin_user_devise_mailer
class AdminUserDeviseMailerPreview < ActionMailer::Preview
  # メールアドレス確認のお願い
  # def confirmation_instructions
  #   admin_user = FactoryBot.build_stubbed(:admin_user)
  #   token = Faker::Internet.password(min_length: 20, max_length: 20)
  #   DeviseMailer.confirmation_instructions(admin_user, token)
  # end

  # パスワード再設定方法のお知らせ
  def reset_password_instructions
    admin_user = FactoryBot.build_stubbed(:admin_user)
    token = Faker::Internet.password(min_length: 20, max_length: 20)
    DeviseMailer.reset_password_instructions(admin_user, token)
  end

  # アカウントロックのお知らせ
  def unlock_instructions
    admin_user = FactoryBot.build_stubbed(:admin_user)
    token = Faker::Internet.password(min_length: 20, max_length: 20)
    DeviseMailer.unlock_instructions(admin_user, token)
  end

  # メールアドレス変更受け付けのお知らせ
  def email_changed
    admin_user = FactoryBot.build_stubbed(:admin_user, unconfirmed_email: Faker::Internet.email)
    DeviseMailer.email_changed(admin_user)
  end

  # パスワード変更完了のお知らせ
  def password_change
    admin_user = FactoryBot.build_stubbed(:admin_user)
    DeviseMailer.password_change(admin_user)
  end
end
