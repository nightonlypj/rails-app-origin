require 'rails_helper'

RSpec.describe 'Top', type: :request do
  # GET / トップページ
  describe 'GET /index' do
    # テスト内容
    shared_examples_for 'ToOK' do
      it '成功ステータス' do
        get root_path
        expect(response).to be_successful
      end
    end

    # テストケース
    context '未ログイン' do
      it_behaves_like 'ToOK'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like 'ToOK'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it_behaves_like 'ToOK'
    end
  end
end
