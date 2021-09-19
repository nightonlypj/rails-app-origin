require 'rails_helper'

RSpec.describe AdminUser, type: :model do
  # テスト内容（共通）
  shared_examples_for 'Valid' do
    it '保存できる' do
      expect(admin_user).to be_valid
    end
  end
  shared_examples_for 'InValid' do
    it '保存できない' do
      expect(admin_user).to be_invalid
    end
  end

  # 氏名
  # 前提条件
  #   なし
  # テストパターン
  #   ない, 最小文字数よりも少ない, 最小文字数と同じ, 最大文字数と同じ, 最大文字数よりも多い
  describe 'validates :name' do
    let(:admin_user) { FactoryBot.build_stubbed(:admin_user, name: name) }

    # テストケース
    context 'ない' do
      let(:name) { nil }
      it_behaves_like 'InValid'
    end
    context '最小文字数よりも少ない' do
      let(:name) { 'a' * (Settings['user_name_minimum'] - 1) }
      it_behaves_like 'InValid'
    end
    context '最小文字数と同じ' do
      let(:name) { 'a' * Settings['user_name_minimum'] }
      it_behaves_like 'Valid'
    end
    context '最大文字数と同じ' do
      let(:name) { 'a' * Settings['user_name_maximum'] }
      it_behaves_like 'Valid'
    end
    context '最大文字数よりも多い' do
      let(:name) { 'a' * (Settings['user_name_maximum'] + 1) }
      it_behaves_like 'InValid'
    end
  end
end
