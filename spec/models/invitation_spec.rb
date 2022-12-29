require 'rails_helper'

RSpec.describe Invitation, type: :model do
  # テスト内容（共通）
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

  # ステータス
  # テストパターン
  #   削除日時: ある, ない
  #   終了日時: 過去, 未来, ない
  describe '#status' do
    subject { invitation.status }
    let(:invitation) { FactoryBot.create(:invitation, deleted_at: deleted_at, ended_at: ended_at) }

    # テストケース
    context '削除日時がある' do
      let(:deleted_at) { Time.current }
      let(:ended_at)   { nil }
      it_behaves_like 'Value', :deleted
    end
    context '削除日時がない' do
      let(:deleted_at) { nil }
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
  #   ステータス: active, expired, deleted
  describe '#status_i18n' do
    subject { invitation.status_i18n }
    let(:invitation) { FactoryBot.create(:invitation, deleted_at: deleted_at, ended_at: ended_at) }

    # テストケース
    context 'ステータスがactive' do
      let(:deleted_at) { nil }
      let(:ended_at)   { nil }
      it_behaves_like 'Value_i18n', 'enums.invitation.status.active'
    end
    context 'ステータスがexpired' do
      let(:deleted_at) { nil }
      let(:ended_at)   { Time.current - 1.day }
      it_behaves_like 'Value_i18n', 'enums.invitation.status.expired'
    end
    context 'ステータスがdeleted' do
      let(:deleted_at) { Time.current }
      let(:ended_at)   { nil }
      it_behaves_like 'Value_i18n', 'enums.invitation.status.deleted'
    end
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
