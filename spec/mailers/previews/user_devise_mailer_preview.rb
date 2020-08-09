# Preview all emails at http://localhost:3000/rails/mailers/user_devise_mailer
class UserDeviseMailerPreview < ActionMailer::Preview
  # メールアドレス確認のお願い
  def confirmation_instructions
    user = FactoryBot.create(:user)
    token = Faker::Internet.password(min_length: 20, max_length: 20)
    DeviseMailer.confirmation_instructions(user, token)
  end

  # パスワード再設定方法のお知らせ
  def reset_password_instructions
    user = FactoryBot.create(:user)
    token = Faker::Internet.password(min_length: 20, max_length: 20)
    DeviseMailer.reset_password_instructions(user, token)
  end

  # アカウントロックのお知らせ
  def unlock_instructions
    user = FactoryBot.create(:user)
    token = Faker::Internet.password(min_length: 20, max_length: 20)
    DeviseMailer.unlock_instructions(user, token)
  end

  # メールアドレス変更受け付けのお知らせ
  def email_changed
    user = FactoryBot.create(:user, unconfirmed_email: Faker::Internet.email)
    DeviseMailer.email_changed(user)
  end

  # パスワード変更完了のお知らせ
  def password_change
    user = FactoryBot.create(:user)
    DeviseMailer.password_change(user)
  end
end
