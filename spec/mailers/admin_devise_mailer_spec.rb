require 'rails_helper'

RSpec.describe DeviseMailer, type: :mailer do
  # テスト内容（共通）
  shared_examples_for 'Header' do
    it 'タイトル・送信者のメールアドレスが設定と、宛先がユーザーのメールアドレスと一致する' do
      expect(mail.subject).to eq(get_subject(subject))
      expect(mail.from).to eq([Settings.mailer_from.email])
      expect(mail.to).to eq([admin_user.email])
    end
  end

  # パスワード再設定方法のお知らせ
  # 前提条件
  #   未ロック
  describe '#reset_password_instructions' do
    let_it_be(:admin_user) { FactoryBot.build_stubbed(:admin_user) }
    let(:token)   { Devise.token_generator.digest(self, :reset_password_token, SecureRandom.uuid) }
    let(:mail)    { DeviseMailer.reset_password_instructions(admin_user, token) }
    let(:subject) { 'devise.mailer.reset_password_instructions.admin_user_subject' }
    let(:url)     { edit_admin_user_password_url(reset_password_token: token) }

    it_behaves_like 'Header'
    it 'パスワード再設定のURLが含まれる' do
      expect(mail.html_part.body).to include("\"#{url}\"")
      expect(mail.text_part.body).to include(url)
    end
  end

  # アカウントロックのお知らせ
  # 前提条件
  #   ロック中
  describe '#unlock_instructions' do
    let_it_be(:admin_user) { FactoryBot.build_stubbed(:admin_user, :locked) }
    let(:token)   { Devise.token_generator.digest(self, :unlock_token, SecureRandom.uuid) }
    let(:mail)    { DeviseMailer.unlock_instructions(admin_user, token) }
    let(:subject) { 'devise.mailer.unlock_instructions.admin_user_subject' }
    let(:url)     { admin_user_unlock_url(unlock_token: token) }

    it_behaves_like 'Header'
    it 'アカウントロック解除のURLが含まれる' do
      expect(mail.html_part.body).to include("\"#{url}\"")
      expect(mail.text_part.body).to include(url)
    end
  end

  # パスワード変更完了のお知らせ
  describe '#password_change' do
    let_it_be(:admin_user) { FactoryBot.build_stubbed(:admin_user) }
    let(:mail)    { DeviseMailer.password_change(admin_user) }
    let(:subject) { 'devise.mailer.password_change.admin_user_subject' }

    it_behaves_like 'Header'
  end
end
