require 'rails_helper'

RSpec.describe AdminUser, type: :model do
  # 氏名
  # 前提条件
  #   なし
  # テストパターン
  #   ない, 最小文字数よりも少ない, 最小文字数と同じ, 最大文字数と同じ, 最大文字数よりも多い → データ作成
  describe 'validates :name' do
    let(:admin_user) { FactoryBot.build(:admin_user, name: name) }

    # テスト内容
    shared_examples_for 'ToOK' do
      it 'OK' do
        expect(admin_user).to be_valid
      end
    end
    shared_examples_for 'ToNG' do
      it 'NG' do
        expect(admin_user).not_to be_valid
      end
    end

    # テストケース
    context 'ない' do
      let(:name) { nil }
      it_behaves_like 'ToNG'
    end
    context '最小文字数よりも少ない' do
      let(:name) { 'a' * (Settings['user_name_minimum'] - 1) }
      it_behaves_like 'ToNG'
    end
    context '最小文字数と同じ' do
      let(:name) { 'a' * Settings['user_name_minimum'] }
      it_behaves_like 'ToOK'
    end
    context '最大文字数と同じ' do
      let(:name) { 'a' * Settings['user_name_maximum'] }
      it_behaves_like 'ToOK'
    end
    context '最大文字数よりも多い' do
      let(:name) { 'a' * (Settings['user_name_maximum'] + 1) }
      it_behaves_like 'ToNG'
    end
  end
end
