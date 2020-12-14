require 'rails_helper'

# TODO: private未対応
RSpec.describe 'Spaces', type: :request do
  include_context '共通ヘッダー'

  # GET /spaces/new（ベースドメイン） スペース作成
  describe 'GET /new' do
    # テスト内容
    shared_examples_for 'ベースドメイン' do
      it '成功ステータス' do
        get new_space_path, headers: base_headers
        expect(response).to be_successful
      end
    end
    shared_examples_for 'サブドメイン' do
      it 'スペース作成（ベースドメイン）にリダイレクト' do
        get new_space_path, headers: @space_headers
        expect(response).to redirect_to("//#{Settings['base_domain']}#{new_space_path}")
      end
    end

    # 子テストケース
    shared_examples_for '存在するサブドメイン' do
      include_context 'リクエストスペース作成'
      it_behaves_like 'サブドメイン'
    end
    shared_examples_for '存在しないサブドメイン' do
      include_context '存在しないリクエストスペース'
      it_behaves_like 'サブドメイン'
    end

    # テストケース
    context '未ログイン' do
      it_behaves_like 'ベースドメイン'
      it_behaves_like '存在するサブドメイン'
      it_behaves_like '存在しないサブドメイン'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like 'ベースドメイン'
      it_behaves_like '存在するサブドメイン'
      it_behaves_like '存在しないサブドメイン'
    end
  end
end
