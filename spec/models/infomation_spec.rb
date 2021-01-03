require 'rails_helper'

RSpec.describe Infomation, type: :model do
  # 対象かを返却
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ作成
  #   対象: 全員, 自分, 他人 → データ作成
  describe 'def target_user?' do
    let!(:outside_user) { FactoryBot.create(:user) }
    shared_context 'データ作成' do
      let!(:infomation) { FactoryBot.create(:infomation, target: target, user_id: user_id) }
    end

    # テスト内容
    shared_examples_for 'ToOK' do
      include_context 'データ作成'
      it 'true' do
        expect(infomation.target_user?(user)).to eq(true)
      end
    end
    shared_examples_for 'ToNG' do
      include_context 'データ作成'
      it 'false' do
        expect(infomation.target_user?(user)).to eq(false)
      end
    end

    # テストケース
    shared_examples_for '[*]対象が全員' do
      let!(:target) { :All }
      let!(:user_id) { nil }
      it_behaves_like 'ToOK'
    end
    shared_examples_for '[ログイン中/削除予約済み]対象が自分' do
      let!(:target) { :User }
      let!(:user_id) { user.id }
      it_behaves_like 'ToOK'
    end
    shared_examples_for '[*]対象が他人' do
      let!(:target) { :User }
      let!(:user_id) { outside_user.id }
      it_behaves_like 'ToNG'
    end

    context '未ログイン' do
      let!(:user) { nil }
      it_behaves_like '[*]対象が全員'
      # it_behaves_like '[未ログイン]対象が自分' # Tips: 未ログインの為、他人
      it_behaves_like '[*]対象が他人' # Tips: NG
    end
    context 'ログイン中' do
      let!(:user) { FactoryBot.create(:user) }
      it_behaves_like '[*]対象が全員'
      it_behaves_like '[ログイン中/削除予約済み]対象が自分'
      it_behaves_like '[*]対象が他人' # Tips: NG
    end
    context 'ログイン中（削除予約済み）' do
      let!(:user) { FactoryBot.create(:user, destroy_requested_at: Time.current, destroy_schedule_at: Time.current + Settings['destroy_schedule_days'].days) }
      it_behaves_like '[*]対象が全員'
      it_behaves_like '[ログイン中/削除予約済み]対象が自分'
      it_behaves_like '[*]対象が他人' # Tips: NG
    end
  end
end
