require 'rails_helper'

RSpec.describe DeviseMailer, type: :mailer do
  let(:client_config) { 'default' }

  # テスト内容（共通）
  shared_examples_for 'Header' do
    it 'タイトル・送信者のメールアドレスが設定と、宛先がユーザーのメールアドレスと一致する' do
      expect(mail.subject).to eq(get_subject(mail_subject))
      expect(mail.from).to eq([Settings.mailer_from.email])
      expect(mail.to).to eq([user.email])
    end
  end

  # メールアドレス確認のお願い
  # 前提条件
  #   メール未確認
  # テストパターン
  #   リダイレクトURL: ない, ある
  describe '#confirmation_instructions' do
    let(:mail) { DeviseMailer.confirmation_instructions(user, token, { 'client-config': client_config, 'redirect-url': redirect_url }) }
    let(:mail_subject) { 'devise.mailer.confirmation_instructions.subject' }
    let_it_be(:user) { FactoryBot.build_stubbed(:user, :unconfirmed) }
    let(:token) { Devise.token_generator.digest(self, :confirmation_token, SecureRandom.uuid) }

    # テスト内容
    shared_examples_for 'Body' do
      let(:url) { user_confirmation_url(confirmation_token: token) }
      it 'メールアドレス確認のURL（リダイレクトURLなし）が含まれる' do
        expect(mail.html_part.body).to include("\"#{url}\"")
        expect(mail.text_part.body).to include(url)
      end
    end
    shared_examples_for 'Body(API)' do
      let(:url) { user_auth_confirmation_url(config: client_config, confirmation_token: token, redirect_url:) }
      let(:encode_url) { "#{user_auth_confirmation_url}?#{URI.encode_www_form(config: client_config, confirmation_token: token, redirect_url:)}" }
      it 'メールアドレス確認のURL（リダイレクトURLあり）が含まれる' do
        expect(mail.html_part.body).to include("\"#{encode_url}\"".gsub(/&/, '&amp;'))
        expect(mail.text_part.body).to include(url)
      end
    end

    # テストケース
    context 'リダイレクトURLがない' do
      let(:redirect_url) { nil }
      it_behaves_like 'Header'
      it_behaves_like 'Body'
    end
    context 'リダイレクトURLがある' do
      let(:redirect_url) { FRONT_SITE_URL }
      it_behaves_like 'Header'
      it_behaves_like 'Body(API)'
    end
  end

  # パスワード再設定方法のお知らせ
  # 前提条件
  #   未ロック
  # テストパターン
  #   リダイレクトURL: ない, ある
  describe '#reset_password_instructions' do
    let(:mail) { DeviseMailer.reset_password_instructions(user, token, { 'client-config': client_config, 'redirect-url': redirect_url }) }
    let(:mail_subject) { 'devise.mailer.reset_password_instructions.subject' }
    let_it_be(:user) { FactoryBot.build_stubbed(:user) }
    let(:token) { Devise.token_generator.digest(self, :reset_password_token, SecureRandom.uuid) }

    # テスト内容
    shared_examples_for 'Body' do
      let(:url) { edit_user_password_url(reset_password_token: token) }
      it 'パスワード再設定のURL（リダイレクトURLなし）が含まれる' do
        expect(mail.html_part.body).to include("\"#{url}\"")
        expect(mail.text_part.body).to include(url)
      end
    end
    shared_examples_for 'Body(API)' do
      let(:url) { edit_user_auth_password_url(config: client_config, redirect_url:, reset_password_token: token) }
      let(:encode_url) do
        "#{edit_user_auth_password_url}?#{URI.encode_www_form(config: client_config, redirect_url:, reset_password_token: token)}"
      end
      it 'パスワード再設定のURL（リダイレクトURLあり）が含まれる' do
        expect(mail.html_part.body).to include("\"#{encode_url}\"".gsub(/&/, '&amp;'))
        expect(mail.text_part.body).to include(url)
      end
    end

    # テストケース
    context 'リダイレクトURLがない' do
      let(:redirect_url) { nil }
      it_behaves_like 'Header'
      it_behaves_like 'Body'
    end
    context 'リダイレクトURLがある' do
      let(:redirect_url) { FRONT_SITE_URL }
      it_behaves_like 'Header'
      it_behaves_like 'Body(API)'
    end
  end

  # アカウントロックのお知らせ
  # 前提条件
  #   ロック中
  # テストパターン
  #   リダイレクトURL: ない, ある
  describe '#unlock_instructions' do
    let(:mail) { DeviseMailer.unlock_instructions(user, token, { 'client-config': client_config, 'redirect-url': redirect_url }) }
    let(:mail_subject) { 'devise.mailer.unlock_instructions.subject' }
    let_it_be(:user) { FactoryBot.build_stubbed(:user, :locked) }
    let(:token) { Devise.token_generator.digest(self, :unlock_token, SecureRandom.uuid) }

    # テスト内容
    shared_examples_for 'Body' do
      let(:url) { user_unlock_url(unlock_token: token) }
      it 'アカウントロック解除のURL（リダイレクトURLなし）が含まれる' do
        expect(mail.html_part.body).to include("\"#{url}\"")
        expect(mail.text_part.body).to include(url)
      end
    end
    shared_examples_for 'Body(API)' do
      let(:url)        { user_auth_unlock_url(config: client_config, redirect_url:, unlock_token: token) }
      let(:encode_url) { "#{user_auth_unlock_url}?#{URI.encode_www_form(config: client_config, redirect_url:, unlock_token: token)}" }
      it 'アカウントロック解除のURL（リダイレクトURLあり）が含まれる' do
        expect(mail.html_part.body).to include("\"#{encode_url}\"".gsub(/&/, '&amp;'))
        expect(mail.text_part.body).to include(url)
      end
    end

    # テストケース
    context 'リダイレクトURLがない' do
      let(:redirect_url) { nil }
      it_behaves_like 'Header'
      it_behaves_like 'Body'
    end
    context 'リダイレクトURLがある' do
      let(:redirect_url) { FRONT_SITE_URL }
      it_behaves_like 'Header'
      it_behaves_like 'Body(API)'
    end
  end

  # メールアドレス変更受け付けのお知らせ
  # 前提条件
  #   メールアドレス変更中
  describe '#email_changed' do
    let(:mail) { DeviseMailer.email_changed(user) }
    let(:mail_subject) { 'devise.mailer.email_changed.subject' }
    let_it_be(:user) { FactoryBot.build_stubbed(:user, :email_changed) }

    it_behaves_like 'Header'
    it '確認待ちメールアドレスが含まれる' do
      expect(mail.html_part.body).to include(user.unconfirmed_email)
      expect(mail.text_part.body).to include(user.unconfirmed_email)
    end
  end

  # パスワード変更完了のお知らせ
  describe '#password_change' do
    let(:mail) { DeviseMailer.password_change(user) }
    let(:mail_subject) { 'devise.mailer.password_change.subject' }
    let_it_be(:user) { FactoryBot.build_stubbed(:user) }

    it_behaves_like 'Header'
  end
end
