require 'rails_helper'

RSpec.describe UserMailer, type: :mailer do
  # テスト内容（共通）
  shared_examples_for 'Header' do
    it 'タイトル・送信者のメールアドレスが設定と、宛先がユーザーのメールアドレスと一致する' do
      expect(mail.subject).to eq(get_subject(subject))
      expect(mail.from).to eq([Settings['mailer_from']['email']])
      expect(mail.to).to eq([user.email])
    end
  end

  # アカウント削除受け付けのお知らせ
  # 前提条件
  #   削除予約済み
  # テストパターン
  #   なし
  describe '#destroy_reserved' do
    let_it_be(:user) { FactoryBot.create(:user, :destroy_reserved) }
    let(:mail)    { UserMailer.with(user: user).destroy_reserved }
    let(:subject) { 'mailer.user.destroy_reserved.subject' }
    let(:url)     { delete_undo_user_registration_url }

    it_behaves_like 'Header'
    it 'アカウント削除取り消しのURLが含まれる' do
      expect(mail.html_part.body).to include("\"#{url}\"")
      expect(mail.text_part.body).to include(url)
    end
  end

  # アカウント削除取り消し完了のお知らせ
  # 前提条件
  #   削除予約なし
  # テストパターン
  #   なし
  describe '#undo_destroy_reserved' do
    let_it_be(:user) { FactoryBot.create(:user) }
    let(:mail)    { UserMailer.with(user: user).undo_destroy_reserved }
    let(:subject) { 'mailer.user.undo_destroy_reserved.subject' }

    it_behaves_like 'Header'
  end

  # アカウント削除完了のお知らせ
  # 前提条件
  #   削除予約済み
  # テストパターン
  #   なし
  describe '#destroy_completed' do
    let_it_be(:user) { FactoryBot.create(:user, :destroy_reserved) }
    let(:mail)    { UserMailer.with(user: user).destroy_completed }
    let(:subject) { 'mailer.user.destroy_completed.subject' }

    it_behaves_like 'Header'
  end
end
