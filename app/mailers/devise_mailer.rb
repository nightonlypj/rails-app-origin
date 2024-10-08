class DeviseMailer < Devise::Mailer
  layout 'mailer'

  # メールアドレス確認のお願い
  def confirmation_instructions(record, token, opts = {})
    opts[:redirect_url] = record.redirect_url if record.is_a?(User) && record.redirect_url.present? # NOTE: /users/auth/updateで使用
    send_mail(super)
  end

  # パスワード再設定方法のお知らせ
  def reset_password_instructions(record, token, opts = {})
    send_mail(super)
  end

  # アカウントロックのお知らせ
  def unlock_instructions(record, token, opts = {})
    opts[:redirect_url] = record.redirect_url if record.is_a?(User) && record.redirect_url.present? # NOTE: /users/auth/sign_inで使用
    send_mail(super)
  end

  # メールアドレス変更受け付けのお知らせ
  def email_changed(record, opts = {})
    send_mail(super)
  end

  # パスワード変更完了のお知らせ
  def password_change(record, opts = {})
    send_mail(super)
  end

  private

  # メール送信
  def send_mail(mail)
    mail.from = "\"#{Settings.mailer_from.name.gsub('%{app_name}', t('app_name'))}\" <#{Settings.mailer_from.email}>"
    mail.subject = mail.subject.gsub('%{app_name}', t('app_name')).gsub('%{env_name}', t("env_name.#{Settings.server_env}"))
    mail
  end
end
