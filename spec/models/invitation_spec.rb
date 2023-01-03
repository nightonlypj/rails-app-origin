require 'rails_helper'

RSpec.describe Invitation, type: :model do
  # テスト内容（共通）
  shared_examples_for 'Valid' do
    it '保存できる' do
      expect(invitation).to be_valid
    end
  end
  shared_examples_for 'InValid' do |key, error_msg|
    it '保存できない。エラーメッセージが一致する' do
      expect(invitation).to be_invalid
      expect(invitation.errors[key]).to eq([error_msg])
    end
  end

  shared_examples_for 'Value' do |value|
    it "#{value}が返却される" do
      is_expected.to eq(value)
    end
  end
  shared_examples_for 'Value_i18n' do |value|
    it "#{value}が返却される" do
      is_expected.to eq(I18n.t(value))
    end
  end

  # コード
  # テストパターン
  #   ない, 正常値, 重複
  describe 'validates :code' do
    let(:invitation) { FactoryBot.build_stubbed(:invitation, code: code) }
    let(:valid_code) { Digest::MD5.hexdigest(SecureRandom.uuid) }

    # テストケース
    context 'ない' do
      let(:code) { nil }
      it_behaves_like 'InValid', :code, I18n.t('activerecord.errors.models.invitation.attributes.code.blank')
    end
    context '正常値' do
      let(:code) { valid_code }
      it_behaves_like 'Valid'
    end
    context '重複' do
      let(:code) { valid_code }
      before { FactoryBot.create(:invitation, code: code) }
      it_behaves_like 'InValid', :code, I18n.t('activerecord.errors.models.invitation.attributes.code.taken')
    end
  end

  # 権限
  # テストパターン
  #   ない, 正常値
  describe 'validates :power' do
    let(:invitation) { FactoryBot.build_stubbed(:invitation, power: power) }

    # テストケース
    context 'ない' do
      let(:power) { nil }
      it_behaves_like 'InValid', :power, I18n.t('activerecord.errors.models.invitation.attributes.power.blank')
    end
    context '正常値' do
      let(:power) { :admin }
      it_behaves_like 'Valid'
    end
  end

  # メモ
  describe 'validates :memo' do
    # TODO
  end

  # 終了日時（日付）
  describe 'validates :ended_date' do
    # TODO
  end

  # 終了日時（時間）
  describe 'validates :ended_time' do
    # TODO
  end

  # 終了日時（タイムゾーン）
  describe 'validates :ended_zone' do
    # TODO
  end

  # ステータス
  # テストパターン
  #   参加日時: ある, ない
  #   削除予定日時: ある, ない
  #   終了日時: 過去, 未来, ない
  describe '#status' do
    subject { invitation.status }
    let(:invitation) { FactoryBot.create(:invitation, ended_at: ended_at, destroy_schedule_at: destroy_schedule_at, email_joined_at: email_joined_at) }

    # テストケース
    context '参加日時がある' do
      let(:email_joined_at)     { Time.current }
      let(:destroy_schedule_at) { nil }
      let(:ended_at)            { nil }
      it_behaves_like 'Value', :email_joined
    end
    context '削除予定日時がある' do
      let(:email_joined_at)     { nil }
      let(:destroy_schedule_at) { Time.current }
      let(:ended_at)            { nil }
      it_behaves_like 'Value', :deleted
    end
    context '削除予定日時がない' do
      let(:email_joined_at)     { nil }
      let(:destroy_schedule_at) { nil }
      context '終了日時が過去' do
        let(:ended_at) { Time.current - 1.day }
        it_behaves_like 'Value', :expired
      end
      context '終了日時が未来' do
        let(:ended_at) { Time.current + 1.day }
        it_behaves_like 'Value', :active
      end
      context '終了日時がない' do
        let(:ended_at) { nil }
        it_behaves_like 'Value', :active
      end
    end
  end

  # ステータス（表示）
  # テストパターン
  #   ステータス: active, expired, deleted, email_joined
  describe '#status_i18n' do
    subject { invitation.status_i18n }
    let(:invitation) { FactoryBot.create(:invitation, ended_at: ended_at, destroy_schedule_at: destroy_schedule_at, email_joined_at: email_joined_at) }

    # テストケース
    context 'ステータスがactive' do
      let(:destroy_schedule_at) { nil }
      let(:ended_at)            { nil }
      let(:email_joined_at)     { nil }
      it_behaves_like 'Value_i18n', 'enums.invitation.status.active'
    end
    context 'ステータスがexpired' do
      let(:destroy_schedule_at) { nil }
      let(:ended_at)            { Time.current - 1.day }
      let(:email_joined_at)     { nil }
      it_behaves_like 'Value_i18n', 'enums.invitation.status.expired'
    end
    context 'ステータスがdeleted' do
      let(:destroy_schedule_at) { Time.current }
      let(:ended_at)            { nil }
      let(:email_joined_at)     { nil }
      it_behaves_like 'Value_i18n', 'enums.invitation.status.deleted'
    end
    context 'ステータスがemail_joined' do
      let(:destroy_schedule_at) { nil }
      let(:ended_at)            { nil }
      let(:email_joined_at)     { Time.current }
      it_behaves_like 'Value_i18n', 'enums.invitation.status.email_joined'
    end
  end

  # ドメイン（配列）
  describe '#domains_array' do
    # TODO
  end

  # 最終更新日時
  # テストパターン
  #   更新日時: 作成日時と同じ, 作成日時以降
  describe '#last_updated_at' do
    subject { invitation.last_updated_at }

    # テストケース
    context '更新日時が作成日時と同じ' do
      let(:invitation) { FactoryBot.create(:invitation) }
      it 'なし' do
        is_expected.to eq(nil)
      end
    end
    context '更新日時が作成日時以降' do
      let(:invitation) { FactoryBot.create(:invitation, created_at: Time.current - 1.hour, updated_at: Time.current) }
      it '更新日時' do
        is_expected.to eq(invitation.updated_at)
      end
    end
  end
end
