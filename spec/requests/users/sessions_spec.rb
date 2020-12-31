require 'rails_helper'

RSpec.describe 'Users::Sessions', type: :request do
  include_context 'リクエストスペース作成'

  # GET /users/sign_in ログイン
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  #   ベースドメイン, 存在するサブドメイン, 存在しないサブドメイン → 事前にデータ作成
  describe 'GET /new' do
    # テスト内容
    shared_examples_for 'ToOK' do
      it '成功ステータス' do
        get new_user_session_path, headers: headers
        expect(response).to be_successful
      end
    end
    shared_examples_for 'ToTop' do
      it 'トップページにリダイレクト' do
        get new_user_session_path, headers: headers
        expect(response).to redirect_to(root_path)
      end
    end
    shared_examples_for 'ToBase' do
      it 'ベースドメインにリダイレクト' do
        get new_user_session_path, headers: headers
        expect(response).to redirect_to("//#{Settings['base_domain']}#{new_user_session_path}")
      end
    end

    # テストケース
    shared_examples_for '[未ログイン]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'ToOK'
    end
    shared_examples_for '[ログイン中]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'ToTop'
    end
    shared_examples_for '[未ログイン]存在するサブドメイン' do
      let!(:headers) { @space_header }
      it_behaves_like 'ToBase'
    end
    shared_examples_for '[ログイン中]存在するサブドメイン' do
      let!(:headers) { @space_header }
      it_behaves_like 'ToTop'
    end
    shared_examples_for '[未ログイン]存在しないサブドメイン' do
      let!(:headers) { NOT_SPACE_HEADER }
      it_behaves_like 'ToBase'
    end
    shared_examples_for '[ログイン中]存在しないサブドメイン' do
      let!(:headers) { NOT_SPACE_HEADER }
      it_behaves_like 'ToTop'
    end

    context '未ログイン' do
      it_behaves_like '[未ログイン]ベースドメイン'
      it_behaves_like '[未ログイン]存在するサブドメイン'
      it_behaves_like '[未ログイン]存在しないサブドメイン'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[ログイン中]ベースドメイン'
      it_behaves_like '[ログイン中]存在するサブドメイン'
      it_behaves_like '[ログイン中]存在しないサブドメイン'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it_behaves_like '[ログイン中]ベースドメイン'
      it_behaves_like '[ログイン中]存在するサブドメイン'
      it_behaves_like '[ログイン中]存在しないサブドメイン'
    end
  end

  # POST /users/sign_in ログイン(処理)
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  #   有効なパラメータ, 無効なパラメータ → 事前にデータ作成
  #   ベースドメイン, 存在するサブドメイン, 存在しないサブドメイン → 事前にデータ作成
  describe 'POST /create' do
    let!(:login_user) { FactoryBot.create(:user) }
    let!(:valid_attributes) { FactoryBot.attributes_for(:user, email: login_user.email, password: login_user.password) }
    let!(:invalid_attributes) { FactoryBot.attributes_for(:user, email: login_user.email, password: nil) }

    # テスト内容
    shared_examples_for 'ToOK' do
      it '成功ステータス' do
        post user_session_path, params: { user: attributes }, headers: headers
        expect(response).to be_successful
      end
    end
    shared_examples_for 'ToNG' do
      it '存在しないステータス' do
        post user_session_path, params: { user: attributes }, headers: headers
        expect(response).to be_not_found
      end
    end
    shared_examples_for 'ToTop' do
      it 'トップページにリダイレクト' do
        post user_session_path, params: { user: attributes }, headers: headers
        expect(response).to redirect_to(root_path)
      end
    end

    # テストケース
    shared_examples_for '[未ログイン][有効なパラメータ]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'ToTop' # Tips: OK
    end
    shared_examples_for '[ログイン中][有効なパラメータ]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'ToTop' # Tips: NG
    end
    shared_examples_for '[未ログイン][無効なパラメータ]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'ToOK' # Tips: 再入力
    end
    shared_examples_for '[ログイン中][無効なパラメータ]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'ToTop'
    end
    shared_examples_for '[未ログイン]存在するサブドメイン' do
      let!(:headers) { @space_header }
      it_behaves_like 'ToNG'
    end
    shared_examples_for '[ログイン中]存在するサブドメイン' do
      let!(:headers) { @space_header }
      it_behaves_like 'ToTop'
    end
    shared_examples_for '[未ログイン]存在しないサブドメイン' do
      let!(:headers) { NOT_SPACE_HEADER }
      it_behaves_like 'ToNG'
    end
    shared_examples_for '[ログイン中]存在しないサブドメイン' do
      let!(:headers) { NOT_SPACE_HEADER }
      it_behaves_like 'ToTop'
    end

    shared_examples_for '[未ログイン]有効なパラメータ' do
      let!(:attributes) { valid_attributes }
      it_behaves_like '[未ログイン][有効なパラメータ]ベースドメイン'
      it_behaves_like '[未ログイン]存在するサブドメイン'
      it_behaves_like '[未ログイン]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中]有効なパラメータ' do
      let!(:attributes) { valid_attributes }
      it_behaves_like '[ログイン中][有効なパラメータ]ベースドメイン'
      it_behaves_like '[ログイン中]存在するサブドメイン'
      it_behaves_like '[ログイン中]存在しないサブドメイン'
    end
    shared_examples_for '[未ログイン]無効なパラメータ' do
      let!(:attributes) { invalid_attributes }
      it_behaves_like '[未ログイン][無効なパラメータ]ベースドメイン'
      it_behaves_like '[未ログイン]存在するサブドメイン'
      it_behaves_like '[未ログイン]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中]無効なパラメータ' do
      let!(:attributes) { invalid_attributes }
      it_behaves_like '[ログイン中][無効なパラメータ]ベースドメイン'
      it_behaves_like '[ログイン中]存在するサブドメイン'
      it_behaves_like '[ログイン中]存在しないサブドメイン'
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
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  #   ベースドメイン, 存在するサブドメイン, 存在しないサブドメイン → 事前にデータ作成
  describe 'DELETE /destroy' do
    # テスト内容
    shared_examples_for 'ToNG' do
      it '存在しないステータス' do
        delete destroy_user_session_path, headers: headers
        expect(response).to be_not_found
      end
    end
    shared_examples_for 'ToLogin' do
      it 'ログインにリダイレクト' do
        delete destroy_user_session_path, headers: headers
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    # テストケース
    shared_examples_for '[未ログイン]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'ToLogin'
    end
    shared_examples_for '[ログイン中]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'ToLogin' # Tips: OK
    end
    shared_examples_for '[未ログイン]存在するサブドメイン' do
      let!(:headers) { @space_header }
      it_behaves_like 'ToLogin'
    end
    shared_examples_for '[ログイン中]存在するサブドメイン' do
      let!(:headers) { @space_header }
      it_behaves_like 'ToNG'
    end
    shared_examples_for '[未ログイン]存在しないサブドメイン' do
      let!(:headers) { NOT_SPACE_HEADER }
      it_behaves_like 'ToLogin'
    end
    shared_examples_for '[ログイン中]存在しないサブドメイン' do
      let!(:headers) { NOT_SPACE_HEADER }
      it_behaves_like 'ToNG'
    end

    context '未ログイン' do
      it_behaves_like '[未ログイン]ベースドメイン'
      it_behaves_like '[未ログイン]存在するサブドメイン'
      it_behaves_like '[未ログイン]存在しないサブドメイン'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[ログイン中]ベースドメイン'
      it_behaves_like '[ログイン中]存在するサブドメイン'
      it_behaves_like '[ログイン中]存在しないサブドメイン'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it_behaves_like '[ログイン中]ベースドメイン'
      it_behaves_like '[ログイン中]存在するサブドメイン'
      it_behaves_like '[ログイン中]存在しないサブドメイン'
    end
  end
end
