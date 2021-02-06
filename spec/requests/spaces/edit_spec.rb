require 'rails_helper'

# TODO
RSpec.describe 'Spaces', type: :request do
=begin
  include_context '共通ヘッダー'
  include_context 'リクエストスペース作成'

  # GET /spaces/edit（サブドメイン） スペース情報変更
  describe 'GET /edit' do
    # テスト内容
    shared_examples_for 'ベースドメイン' do
      it '存在しないステータス' do
        get edit_space_path, headers: base_headers
        expect(response).to be_not_found
      end
    end
    shared_examples_for '存在するサブドメイン' do
      it '成功ステータス' do
        get edit_space_path, headers: @space_headers
        expect(response).to be_successful
      end
    end
    shared_examples_for '存在しないサブドメイン' do
      it '存在しないステータス' do
        get edit_space_path, headers: not_space_headers
        expect(response).to be_not_found
      end
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
=end
end
