require 'rails_helper'

RSpec.describe UserMailer, type: :mailer do
  # アカウント削除受け付けのお知らせ
  describe 'destroy_reserved' do
    let(:user) { FactoryBot.create(:user, destroy_schedule_at: Time.current + Settings['destroy_schedule_days'].days) }
    let(:mail) { UserMailer.with(user: user).destroy_reserved }
    it '送信者のメールアドレスが設定と一致' do
      expect(mail.from).to eq([Settings['mailer_from']['email']])
    end
    it '宛先がユーザーのメールアドレスと一致' do
      expect(mail.to).to eq([user.email])
    end
    it '本文(html)にアカウント削除取り消しのURLが含まれる' do
      expect(mail.html_part.body).to include("\"#{users_undo_delete_url}\"")
    end
    it '本文(text)にアカウント削除取り消しのURLが含まれる' do
      expect(mail.text_part.body).to include(users_undo_delete_url)
    end
  end

  # アカウント削除取り消し完了のお知らせ
  describe 'undo_destroy_reserved' do
    let(:user) { FactoryBot.create(:user) }
    let(:mail) { UserMailer.with(user: user).undo_destroy_reserved }
    it '送信者のメールアドレスが設定と一致' do
      expect(mail.from).to eq([Settings['mailer_from']['email']])
    end
    it '宛先がユーザーのメールアドレスと一致' do
      expect(mail.to).to eq([user.email])
    end
  end

  # アカウント削除完了のお知らせ
  describe 'destroy_completed' do
    let(:user) { FactoryBot.create(:user) }
    let(:mail) { UserMailer.with(user: user).destroy_completed }
    it '送信者のメールアドレスが設定と一致' do
      expect(mail.from).to eq([Settings['mailer_from']['email']])
    end
    it '宛先がユーザーのメールアドレスと一致' do
      expect(mail.to).to eq([user.email])
    end
  end

  # メンバー登録のお願い
  # 前提条件
  #   なし
  # テストパターン
  #   メンバー: いる, いない（解除済み） → データ作成
  #   招待者: いる, いない（削除済み） → データ作成
  #   顧客: ある, ない（削除済み） → データ作成
  describe 'member_create' do
    let(:user) do
      FactoryBot.build_stubbed(:user, name: '-' * Settings['user_name_minimum'], invitation_token: Digest::MD5.hexdigest(SecureRandom.uuid),
                                      invitation_requested_at: Time.current)
    end

    # テスト内容
    shared_examples_for '[*][*][*]メール送信' do
      let(:mail) { UserMailer.with(user: user, member: member, customer: customer, invitation_user: invitation_user).member_create }
      it '送信者のメールアドレスが設定と一致' do
        expect(mail.from).to eq([Settings['mailer_from']['email']])
      end
      it '宛先がユーザーのメールアドレスと一致' do
        expect(mail.to).to eq([user.email])
      end
    end

    # テストケース
    shared_examples_for '[*][*]顧客がある' do
      let(:customer) { FactoryBot.build_stubbed(:customer) }
      it_behaves_like '[*][*][*]メール送信'
    end
    shared_examples_for '[*][*]顧客がない' do
      let(:customer) { nil }
      it_behaves_like '[*][*][*]メール送信'
    end

    shared_examples_for '[*]招待者がいる' do
      let(:invitation_user) { FactoryBot.build_stubbed(:user) }
      it_behaves_like '[*][*]顧客がある'
      it_behaves_like '[*][*]顧客がない'
    end
    shared_examples_for '[*]招待者がいない' do
      let(:invitation_user) { nil }
      it_behaves_like '[*][*]顧客がある'
      it_behaves_like '[*][*]顧客がない'
    end

    context 'メンバーにいる' do
      let(:member) { FactoryBot.build_stubbed(:member, power: :Member, invitationed_at: Time.current) }
      it_behaves_like '[*]招待者がいる'
      it_behaves_like '[*]招待者がいない'
    end
    context 'メンバーにいない' do
      let(:member) { nil }
      it_behaves_like '[*]招待者がいる'
      it_behaves_like '[*]招待者がいない'
    end
  end
end
