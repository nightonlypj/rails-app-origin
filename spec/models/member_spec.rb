require 'rails_helper'

RSpec.describe Member, type: :model do
  # テスト内容（共通）
  shared_examples_for 'Valid' do
    it '保存できる' do
      expect(member).to be_valid
    end
  end
  shared_examples_for 'InValid' do |key, error_msg|
    it '保存できない。エラーメッセージが一致する' do
      expect(member).to be_invalid
      expect(member.errors[key]).to eq([error_msg])
    end
  end

  # 権限
  # テストパターン
  #   ない, 正常値
  describe 'validates :power' do
    let(:member) { FactoryBot.build_stubbed(:member, power: power) }

    # テストケース
    context 'ない' do
      let(:power) { nil }
      it_behaves_like 'InValid', :power, I18n.t('activerecord.errors.models.member.attributes.power.blank')
    end
    context '正常値' do
      let(:power) { :admin }
      it_behaves_like 'Valid'
    end
  end

  # 招待日時
  # テストパターン
  #   招待者: いない, いる
  describe '#invitationed_at' do
    subject { member.invitationed_at }

    # テストケース
    context '招待者がいない' do
      let(:member) { FactoryBot.create(:member, invitationed_user: nil) }
      it 'なし' do
        is_expected.to eq(nil)
      end
    end
    context '招待者がいる' do
      let(:user)   { FactoryBot.create(:user) }
      let(:member) { FactoryBot.create(:member, invitationed_user: user) }
      it '作成日時' do
        is_expected.to eq(member.created_at)
      end
    end
  end

  # 最終更新日時
  # テストパターン
  #   更新日時: 作成日時と同じ, 作成日時以降
  describe '#last_updated_at' do
    subject { member.last_updated_at }

    # テストケース
    context '更新日時が作成日時と同じ' do
      let(:member) { FactoryBot.create(:member) }
      it 'なし' do
        is_expected.to eq(nil)
      end
    end
    context '更新日時が作成日時以降' do
      let(:member) { FactoryBot.create(:member, created_at: Time.current - 1.hour, updated_at: Time.current) }
      it '更新日時' do
        is_expected.to eq(member.updated_at)
      end
    end
  end
end
