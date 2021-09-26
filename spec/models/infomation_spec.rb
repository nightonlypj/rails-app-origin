# TODO: 直す

require 'rails_helper'

RSpec.describe Infomation, type: :model do
  # 対象かを返却
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み）
  #   対象: 全員, 自分, 他人
  describe '#target_user?' do
    subject { infomation.target_user?(user) }
    let(:infomation)   { FactoryBot.create(:infomation, target: target, user_id: user_id) }
    let(:outside_user) { FactoryBot.create(:user) }

    # テスト内容
    shared_examples_for 'OK' do
      it 'true' do
        is_expected.to eq(true)
      end
    end
    shared_examples_for 'NG' do
      it 'false' do
        is_expected.to eq(false)
      end
    end

    # テストケース
    shared_examples_for '[*]対象が全員' do
      let(:user_id) { nil }
      let(:target)  { :All }
      it_behaves_like 'OK'
    end
    shared_examples_for '[ログイン中/削除予約済み]対象が自分' do
      let(:user_id) { user.id }
      let(:target)  { :User }
      it_behaves_like 'OK'
    end
    shared_examples_for '[*]対象が他人' do
      let(:user_id) { outside_user.id }
      let(:target)  { :User }
      it_behaves_like 'NG'
    end

    context '未ログイン' do
      let(:user) { nil }
      it_behaves_like '[*]対象が全員'
      # it_behaves_like '[未ログイン]対象が自分' # Tips: 未ログインの為、他人
      it_behaves_like '[*]対象が他人'
    end
    context 'ログイン中' do
      let(:user) { FactoryBot.create(:user) }
      it_behaves_like '[*]対象が全員'
      it_behaves_like '[ログイン中/削除予約済み]対象が自分'
      it_behaves_like '[*]対象が他人'
    end
    context 'ログイン中（削除予約済み）' do
      let(:user) { FactoryBot.create(:user_destroy_reserved) }
      it_behaves_like '[*]対象が全員'
      it_behaves_like '[ログイン中/削除予約済み]対象が自分'
      it_behaves_like '[*]対象が他人'
    end
  end
end
