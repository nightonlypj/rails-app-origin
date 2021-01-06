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
  describe 'member_create' do
    let(:user) { FactoryBot.build_stubbed(:user, name: '-', invitation_token: Digest::MD5.hexdigest(SecureRandom.uuid), invitation_requested_at: Time.current) }
    let(:member) { FactoryBot.build_stubbed(:member, power: :Member, invitationed_at: Time.current) }
    let(:customer) { FactoryBot.build_stubbed(:customer) }
    let(:current_user) { FactoryBot.build_stubbed(:user) }
    let(:mail) { UserMailer.with(user: user, member: member, customer: customer, current_user: current_user).member_create }
    it '送信者のメールアドレスが設定と一致' do
      expect(mail.from).to eq([Settings['mailer_from']['email']])
    end
    it '宛先がユーザーのメールアドレスと一致' do
      expect(mail.to).to eq([user.email])
    end
  end
end
