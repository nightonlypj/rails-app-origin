class DeviseMailer < Devise::Mailer
  def confirmation_instructions(record, token, opts = {})
    update_mail_subject(super)
  end

  def reset_password_instructions(record, token, opts = {})
    update_mail_subject(super)
  end

  def unlock_instructions(record, token, opts = {})
    update_mail_subject(super)
  end

  def email_changed(record, opts = {})
    update_mail_subject(super)
  end

  def password_change(record, opts = {})
    update_mail_subject(super)
  end

  private

  # メールタイトルにアプリ名を追加
  def update_mail_subject(mail)
    mail.subject = mail.subject.gsub(/%{app_name}/, t('app_name'))
    mail
  end
end
