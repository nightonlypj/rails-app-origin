require 'rails_helper'

RSpec.describe 'Admin', type: :request do
  # GET / RailsAdmin
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み）, ログイン中（管理者） → データ＆状態作成
  describe 'GET /' do
    # テスト内容
    shared_examples_for 'ToOK' do
      it '成功ステータス' do
        get rails_admin_path
        expect(response).to be_successful
      end
    end
    shared_examples_for 'ToLogin' do
      it 'ログイン（管理者）にリダイレクト' do
        get rails_admin_path
        expect(response).to redirect_to(new_admin_user_session_path)
      end
    end

    # テストケース
    context '未ログイン' do
      it_behaves_like 'ToLogin'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like 'ToLogin'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it_behaves_like 'ToLogin'
    end
    context 'ログイン中（管理者）' do
      include_context 'ログイン処理（管理者）'
      it_behaves_like 'ToOK'
    end
  end
end
