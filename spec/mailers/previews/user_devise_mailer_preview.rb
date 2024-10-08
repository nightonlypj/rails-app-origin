# Preview all emails at http://localhost:3000/rails/mailers/user_devise_mailer
class UserDeviseMailerPreview < ActionMailer::Preview
  # メールアドレス確認のお願い
  def confirmation_instructions(redirect_url = nil)
    user = FactoryBot.build_stubbed(:user, :unconfirmed)
    DeviseMailer.confirmation_instructions(user, token, { 'client-config': 'default', 'redirect-url': redirect_url })
  end

  def confirmation_instructions_auth
    redirect_url = Faker::Internet.url(scheme: 'https')
    confirmation_instructions(redirect_url)
  end

  # パスワード再設定方法のお知らせ
  def reset_password_instructions(redirect_url = nil)
    user = FactoryBot.build_stubbed(:user)
    DeviseMailer.reset_password_instructions(user, token, { 'client-config': 'default', 'redirect-url': redirect_url })
  end

  def reset_password_instructions_auth
    redirect_url = Faker::Internet.url(scheme: 'https')
    reset_password_instructions(redirect_url)
  end

  # アカウントロックのお知らせ
  def unlock_instructions(redirect_url = nil)
    user = FactoryBot.build_stubbed(:user, :locked)
    DeviseMailer.unlock_instructions(user, token, { 'client-config': 'default', 'redirect-url': redirect_url })
  end

  def unlock_instructions_auth
    redirect_url = Faker::Internet.url(scheme: 'https')
    unlock_instructions(redirect_url)
  end

  # メールアドレス変更受け付けのお知らせ
  def email_changed
    user = FactoryBot.build_stubbed(:user, :email_changed)
    DeviseMailer.email_changed(user)
  end

  # パスワード変更完了のお知らせ
  def password_change
    user = FactoryBot.build_stubbed(:user)
    DeviseMailer.password_change(user)
  end

  private

  def token
    Faker::Internet.password(min_length: 20, max_length: 20)
  end
end
