require 'rails_helper'

RSpec.describe 'AdminUsers::Sessions', type: :request do
  # GET /admin_users/sign_in ログイン
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中 → データ＆状態作成
  describe 'GET /new' do
    # テスト内容
    shared_examples_for 'ToOK' do
      it '成功ステータス' do
        get new_admin_user_session_path
        expect(response).to be_successful
      end
    end
    shared_examples_for 'ToAdmin' do
      it 'RailsAdminにリダイレクト' do
        get new_admin_user_session_path
        expect(response).to redirect_to(rails_admin_path)
      end
    end

    # テストケース
    context '未ログイン' do
      it_behaves_like 'ToOK'
    end
    context 'ログイン中' do
      include_context 'ログイン処理（管理者）'
      it_behaves_like 'ToAdmin'
    end
  end

  # POST /admin_users/sign_in ログイン(処理)
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中 → データ＆状態作成
  #   有効なパラメータ, 無効なパラメータ → 事前にデータ作成
  describe 'POST /create' do
    let!(:login_admin_user) { FactoryBot.create(:admin_user) }
    let!(:valid_attributes) { FactoryBot.attributes_for(:admin_user, email: login_admin_user.email, password: login_admin_user.password) }
    let!(:invalid_attributes) { FactoryBot.attributes_for(:admin_user, email: login_admin_user.email, password: nil) }

    # テスト内容
    shared_examples_for 'ToOK' do
      it '成功ステータス' do
        post admin_user_session_path, params: { admin_user: attributes }
        expect(response).to be_successful
      end
    end
    shared_examples_for 'ToAdmin' do
      it 'RailsAdminにリダイレクト' do
        post admin_user_session_path, params: { admin_user: attributes }
        expect(response).to redirect_to(rails_admin_path)
      end
    end

    # テストケース
    shared_examples_for '有効なパラメータ' do # Tips: ログイン中はメッセージ表示
      let!(:attributes) { valid_attributes }
      it_behaves_like 'ToAdmin'
    end
    shared_examples_for '[未ログイン]無効なパラメータ' do
      let!(:attributes) { invalid_attributes }
      it_behaves_like 'ToOK' # Tips: 再入力の為
    end
    shared_examples_for '[ログイン中]無効なパラメータ' do
      let!(:attributes) { invalid_attributes }
      it_behaves_like 'ToAdmin'
    end

    context '未ログイン' do
      it_behaves_like '有効なパラメータ'
      it_behaves_like '[未ログイン]無効なパラメータ'
    end
    context 'ログイン中' do
      include_context 'ログイン処理（管理者）'
      it_behaves_like '有効なパラメータ'
      it_behaves_like '[ログイン中]無効なパラメータ'
    end
  end

  # DELETE /admin_users/sign_out ログアウト(処理)
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中 → データ＆状態作成
  describe 'DELETE /destroy' do
    # テスト内容
    shared_examples_for 'ToLogin' do
      it 'ログインにリダイレクト' do
        delete destroy_admin_user_session_path
        expect(response).to redirect_to(new_admin_user_session_path)
      end
    end

    # テストケース
    context '未ログイン' do
      it_behaves_like 'ToLogin'
    end
    context 'ログイン中' do
      include_context 'ログイン処理（管理者）'
      it_behaves_like 'ToLogin'
    end
  end
end
