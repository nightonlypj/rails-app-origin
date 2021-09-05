# TODO: 直す

require 'rails_helper'

RSpec.describe Infomation, type: :model do
  # 対象かを返却
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ作成
  #   対象: 全員, 自分, 他人 → データ作成
  describe 'target_user?' do
    let(:infomation)   { FactoryBot.create(:infomation, target: target, user_id: user_id) }
    let(:outside_user) { FactoryBot.create(:user) }

    # テスト内容
    shared_examples_for 'ToOK' do
      it 'true' do
        expect(infomation.target_user?(user)).to eq(true)
      end
    end
    shared_examples_for 'ToNG' do
      it 'false' do
        expect(infomation.target_user?(user)).to eq(false)
      end
    end

    # テストケース
    shared_examples_for '[*]対象が全員' do
      let(:user_id) { nil }
      let(:target)  { :All }
      it_behaves_like 'ToOK'
    end
    shared_examples_for '[ログイン中/削除予約済み]対象が自分' do
      let(:user_id) { user.id }
      let(:target)  { :User }
      it_behaves_like 'ToOK'
    end
    shared_examples_for '[*]対象が他人' do
      let(:user_id) { outside_user.id }
      let(:target)  { :User }
      it_behaves_like 'ToNG'
    end

    context '未ログイン' do
      let(:user) { nil }
      it_behaves_like '[*]対象が全員'
      # it_behaves_like '[未ログイン]対象が自分' # Tips: 未ログインの為、他人
      it_behaves_like '[*]対象が他人' # Tips: NG
    end
    context 'ログイン中' do
      let(:user) { FactoryBot.create(:user) }
      it_behaves_like '[*]対象が全員'
      it_behaves_like '[ログイン中/削除予約済み]対象が自分'
      it_behaves_like '[*]対象が他人' # Tips: NG
    end
    context 'ログイン中（削除予約済み）' do
      let(:user) { FactoryBot.create(:user_destroy_reserved) }
      it_behaves_like '[*]対象が全員'
      it_behaves_like '[ログイン中/削除予約済み]対象が自分'
      it_behaves_like '[*]対象が他人' # Tips: NG
    end
  end
end
