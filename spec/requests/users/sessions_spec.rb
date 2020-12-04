require 'rails_helper'

RSpec.describe 'Users::Sessions', type: :request do
  let!(:login_user) { FactoryBot.create(:user) }
  let!(:valid_attributes) { FactoryBot.attributes_for(:user, email: login_user.email, password: login_user.password) }
  let!(:invalid_attributes) { FactoryBot.attributes_for(:user, email: login_user.email, password: nil) }

  # GET /users/sign_in ログイン
  describe 'GET /users/sign_in' do
    # テスト内容
    shared_examples_for 'ToOK' do
      it '成功ステータス' do
        get new_user_session_path
        expect(response).to be_successful
      end
    end
    shared_examples_for 'ToTop' do
      it 'トップページにリダイレクト' do
        get new_user_session_path
        expect(response).to redirect_to(root_path)
      end
    end

    # テストケース
    context '未ログイン' do
      it_behaves_like 'ToOK'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like 'ToTop'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it_behaves_like 'ToTop'
    end
  end

  # POST /users/sign_in ログイン(処理)
  describe 'POST /users/sign_in' do
    # テスト内容
    shared_examples_for 'ToOK' do
      it '成功ステータス' do
        post user_session_path, params: { user: attributes }
        expect(response).to be_successful
      end
    end
    shared_examples_for 'ToTop' do
      it 'トップページにリダイレクト' do
        post user_session_path, params: { user: attributes }
        expect(response).to redirect_to(root_path)
      end
    end

    # テストケース
    shared_examples_for '[未ログイン]有効なパラメータ' do
      let!(:attributes) { valid_attributes }
      it_behaves_like 'ToTop'
    end
    shared_examples_for '[未ログイン]無効なパラメータ' do
      let!(:attributes) { invalid_attributes }
      it_behaves_like 'ToOK' # Tips: 再入力の為
    end
    shared_examples_for '[ログイン中]有効なパラメータ' do
      let!(:attributes) { valid_attributes }
      it_behaves_like 'ToTop'
    end
    shared_examples_for '[ログイン中]無効なパラメータ' do
      let!(:attributes) { invalid_attributes }
      it_behaves_like 'ToTop'
    end

    context '未ログイン' do
      it_behaves_like '[未ログイン]有効なパラメータ'
      it_behaves_like '[未ログイン]無効なパラメータ'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[ログイン中]有効なパラメータ'
      it_behaves_like '[ログイン中]無効なパラメータ'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it_behaves_like '[ログイン中]有効なパラメータ'
      it_behaves_like '[ログイン中]無効なパラメータ'
    end
  end

  # DELETE /users/sign_out ログアウト(処理)
  describe 'DELETE /users/sign_out' do
    # テスト内容
    shared_examples_for 'ToLogin' do
      it 'ログインにリダイレクト' do
        delete destroy_user_session_path
        expect(response).to redirect_to(new_user_session_path)
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
  end
end
