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
    shared_examples_for 'ToTop' do |alert, notice|
      it 'トップページにリダイレクト' do
        get new_user_session_path, headers: headers
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
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
    shared_examples_for '[ログイン中/削除予約済み]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン]存在するサブドメイン' do
      let!(:headers) { @space_header }
      it_behaves_like 'ToBase'
    end
    shared_examples_for '[ログイン中/削除予約済み]存在するサブドメイン' do
      let!(:headers) { @space_header }
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン]存在しないサブドメイン' do
      let!(:headers) { NOT_SPACE_HEADER }
      it_behaves_like 'ToBase'
    end
    shared_examples_for '[ログイン中/削除予約済み]存在しないサブドメイン' do
      let!(:headers) { NOT_SPACE_HEADER }
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
    end

    context '未ログイン' do
      it_behaves_like '[未ログイン]ベースドメイン'
      it_behaves_like '[未ログイン]存在するサブドメイン'
      it_behaves_like '[未ログイン]存在しないサブドメイン'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[ログイン中/削除予約済み]ベースドメイン'
      it_behaves_like '[ログイン中/削除予約済み]存在するサブドメイン'
      it_behaves_like '[ログイン中/削除予約済み]存在しないサブドメイン'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it_behaves_like '[ログイン中/削除予約済み]ベースドメイン'
      it_behaves_like '[ログイン中/削除予約済み]存在するサブドメイン'
      it_behaves_like '[ログイン中/削除予約済み]存在しないサブドメイン'
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
    shared_examples_for 'ToNot' do
      it '存在しないステータス' do
        post user_session_path, params: { user: attributes }, headers: headers
        expect(response).to be_not_found
      end
    end
    shared_examples_for 'ToTop' do |alert, notice|
      it 'トップページにリダイレクト' do
        post user_session_path, params: { user: attributes }, headers: headers
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end

    # テストケース
    shared_examples_for '[未ログイン][有効]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'ToTop', nil, 'devise.sessions.signed_in'
    end
    shared_examples_for '[ログイン中/削除予約済み][有効]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン][無効]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'ToOK' # Tips: 再入力
    end
    shared_examples_for '[ログイン中/削除予約済み][無効]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン][*]存在するサブドメイン' do
      let!(:headers) { @space_header }
      it_behaves_like 'ToNot'
    end
    shared_examples_for '[ログイン中/削除予約済み][*]存在するサブドメイン' do
      let!(:headers) { @space_header }
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン][*]存在しないサブドメイン' do
      let!(:headers) { NOT_SPACE_HEADER }
      it_behaves_like 'ToNot'
    end
    shared_examples_for '[ログイン中/削除予約済み][*]存在しないサブドメイン' do
      let!(:headers) { NOT_SPACE_HEADER }
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
    end

    shared_examples_for '[未ログイン]有効なパラメータ' do
      let!(:attributes) { valid_attributes }
      it_behaves_like '[未ログイン][有効]ベースドメイン'
      it_behaves_like '[未ログイン][*]存在するサブドメイン'
      it_behaves_like '[未ログイン][*]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み]有効なパラメータ' do
      let!(:attributes) { valid_attributes }
      it_behaves_like '[ログイン中/削除予約済み][有効]ベースドメイン'
      it_behaves_like '[ログイン中/削除予約済み][*]存在するサブドメイン'
      it_behaves_like '[ログイン中/削除予約済み][*]存在しないサブドメイン'
    end
    shared_examples_for '[未ログイン]無効なパラメータ' do
      let!(:attributes) { invalid_attributes }
      it_behaves_like '[未ログイン][無効]ベースドメイン'
      it_behaves_like '[未ログイン][*]存在するサブドメイン'
      it_behaves_like '[未ログイン][*]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み]無効なパラメータ' do
      let!(:attributes) { invalid_attributes }
      it_behaves_like '[ログイン中/削除予約済み][無効]ベースドメイン'
      it_behaves_like '[ログイン中/削除予約済み][*]存在するサブドメイン'
      it_behaves_like '[ログイン中/削除予約済み][*]存在しないサブドメイン'
    end

    context '未ログイン' do
      it_behaves_like '[未ログイン]有効なパラメータ'
      it_behaves_like '[未ログイン]無効なパラメータ'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[ログイン中/削除予約済み]有効なパラメータ'
      it_behaves_like '[ログイン中/削除予約済み]無効なパラメータ'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it_behaves_like '[ログイン中/削除予約済み]有効なパラメータ'
      it_behaves_like '[ログイン中/削除予約済み]無効なパラメータ'
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
    shared_examples_for 'ToNot' do
      it '存在しないステータス' do
        delete destroy_user_session_path, headers: headers
        expect(response).to be_not_found
      end
    end
    shared_examples_for 'ToLogin' do |alert, notice|
      it 'ログインにリダイレクト' do
        delete destroy_user_session_path, headers: headers
        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end

    # テストケース
    shared_examples_for '[未ログイン]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'ToLogin', nil, 'devise.sessions.already_signed_out'
    end
    shared_examples_for '[ログイン中/削除予約済み]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'ToLogin', nil, 'devise.sessions.signed_out'
    end
    shared_examples_for '[未ログイン]存在するサブドメイン' do
      let!(:headers) { @space_header }
      it_behaves_like 'ToLogin', nil, 'devise.sessions.already_signed_out'
    end
    shared_examples_for '[ログイン中/削除予約済み]存在するサブドメイン' do
      let!(:headers) { @space_header }
      it_behaves_like 'ToNot'
    end
    shared_examples_for '[未ログイン]存在しないサブドメイン' do
      let!(:headers) { NOT_SPACE_HEADER }
      it_behaves_like 'ToLogin', nil, 'devise.sessions.already_signed_out'
    end
    shared_examples_for '[ログイン中/削除予約済み]存在しないサブドメイン' do
      let!(:headers) { NOT_SPACE_HEADER }
      it_behaves_like 'ToNot'
    end

    context '未ログイン' do
      it_behaves_like '[未ログイン]ベースドメイン'
      it_behaves_like '[未ログイン]存在するサブドメイン'
      it_behaves_like '[未ログイン]存在しないサブドメイン'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[ログイン中/削除予約済み]ベースドメイン'
      it_behaves_like '[ログイン中/削除予約済み]存在するサブドメイン'
      it_behaves_like '[ログイン中/削除予約済み]存在しないサブドメイン'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it_behaves_like '[ログイン中/削除予約済み]ベースドメイン'
      it_behaves_like '[ログイン中/削除予約済み]存在するサブドメイン'
      it_behaves_like '[ログイン中/削除予約済み]存在しないサブドメイン'
    end
  end
end
