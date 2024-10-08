class ApplicationMailer < ActionMailer::Base
  layout 'mailer'

  private

  # メール送信
  def send_mail(subject_key)
    @user = params[:user]
    mail(
      from: "\"#{Settings.mailer_from.name.gsub('%{app_name}', t('app_name'))}\" <#{Settings.mailer_from.email}>",
      to: @user.email,
      subject: t(subject_key, app_name: I18n.t('app_name'), env_name: I18n.t("env_name.#{Settings.server_env}"))
    )
  end
end
