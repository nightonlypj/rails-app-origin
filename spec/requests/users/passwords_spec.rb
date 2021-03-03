require 'rails_helper'

RSpec.describe 'Users::Passwords', type: :request do
  include_context 'リクエストスペース作成'

  # GET /users/password/new パスワード再設定[メール送信]
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  #   ベースドメイン, 存在するサブドメイン, 存在しないサブドメイン → 事前にデータ作成
  describe 'GET /new' do
    # テスト内容
    shared_examples_for 'ToOK' do
      it '成功ステータス' do
        get new_user_password_path, headers: headers
        expect(response).to be_successful
      end
    end
    shared_examples_for 'ToTop' do |alert, notice|
      it 'トップページにリダイレクト' do
        get new_user_password_path, headers: headers
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end
    shared_examples_for 'ToBase' do
      it 'ベースドメインにリダイレクト' do
        get new_user_password_path, headers: headers
        expect(response).to redirect_to("//#{Settings['base_domain']}#{new_user_password_path}")
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

  # POST /users/password パスワード再設定[メール送信](処理)
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  #   有効なパラメータ, 無効なパラメータ → 事前にデータ作成
  #   ベースドメイン, 存在するサブドメイン, 存在しないサブドメイン → 事前にデータ作成
  describe 'POST /create' do
    let!(:send_user) { FactoryBot.create(:user) }
    let!(:valid_attributes) { FactoryBot.attributes_for(:user, email: send_user.email) }
    let!(:invalid_attributes) { FactoryBot.attributes_for(:user, email: nil) }

    # テスト内容
    shared_examples_for 'ToOK' do
      it '成功ステータス' do
        post user_password_path, params: { user: attributes }, headers: headers
        expect(response).to be_successful
      end
    end
    shared_examples_for 'ToNot' do
      it '存在しないステータス' do
        post user_password_path, params: { user: attributes }, headers: headers
        expect(response).to be_not_found
      end
    end
    shared_examples_for 'ToTop' do |alert, notice|
      it 'トップページにリダイレクト' do
        post user_password_path, params: { user: attributes }, headers: headers
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end
    shared_examples_for 'ToLogin' do |alert, notice|
      it 'ログインにリダイレクト' do
        post user_password_path, params: { user: attributes }, headers: headers
        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end

    # テストケース
    shared_examples_for '[未ログイン][有効]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'ToLogin', nil, 'devise.passwords.send_instructions'
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

  # GET /users/password/edit パスワード再設定
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  #   トークン: 期限内, 期限切れ, 存在しない, ない → データ作成
  #   ベースドメイン, 存在するサブドメイン, 存在しないサブドメイン → 事前にデータ作成
  describe 'GET /edit' do
    # テスト内容
    shared_examples_for 'ToOK' do
      it '成功ステータス' do
        get edit_user_password_path(reset_password_token: reset_password_token), headers: headers
        expect(response).to be_successful
      end
    end
    shared_examples_for 'ToTop' do |alert, notice|
      it 'トップページにリダイレクト' do
        get edit_user_password_path(reset_password_token: reset_password_token), headers: headers
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end
    shared_examples_for 'ToLogin' do |alert, notice|
      it 'ログインにリダイレクト' do
        get edit_user_password_path(reset_password_token: reset_password_token), headers: headers
        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end
    shared_examples_for 'ToNew' do |alert, notice|
      it 'パスワード再設定[メール送信]にリダイレクト' do
        get edit_user_password_path(reset_password_token: reset_password_token), headers: headers
        expect(response).to redirect_to(new_user_password_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end
    shared_examples_for 'ToBase' do
      it 'ベースドメインにリダイレクト' do
        get edit_user_password_path(reset_password_token: reset_password_token), headers: headers
        expect(response).to redirect_to("//#{Settings['base_domain']}#{edit_user_password_path(reset_password_token: reset_password_token)}")
      end
    end

    # テストケース
    shared_examples_for '[未ログイン][期限内]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'ToOK'
    end
    shared_examples_for '[未ログイン][期限切れ/存在しない]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'ToNew', 'activerecord.errors.models.user.attributes.reset_password_token.invalid', nil
    end
    shared_examples_for '[未ログイン][ない]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'ToLogin', 'devise.passwords.no_token', nil
    end
    shared_examples_for '[ログイン中/削除予約済み][*]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン][期限内/期限切れ/存在しない]存在するサブドメイン' do
      let!(:headers) { @space_header }
      it_behaves_like 'ToBase'
    end
    shared_examples_for '[未ログイン][ない]存在するサブドメイン' do
      let!(:headers) { @space_header }
      it_behaves_like 'ToLogin', 'devise.passwords.no_token', nil
    end
    shared_examples_for '[ログイン中/削除予約済み][*]存在するサブドメイン' do
      let!(:headers) { @space_header }
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン][期限内/期限切れ/存在しない]存在しないサブドメイン' do
      let!(:headers) { NOT_SPACE_HEADER }
      it_behaves_like 'ToBase'
    end
    shared_examples_for '[未ログイン][ない]存在しないサブドメイン' do
      let!(:headers) { NOT_SPACE_HEADER }
      it_behaves_like 'ToLogin', 'devise.passwords.no_token', nil
    end
    shared_examples_for '[ログイン中/削除予約済み][*]存在しないサブドメイン' do
      let!(:headers) { NOT_SPACE_HEADER }
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
    end

    shared_examples_for '[未ログイン]トークンが期限内' do
      include_context 'パスワードリセットトークン作成', true
      it_behaves_like '[未ログイン][期限内]ベースドメイン'
      it_behaves_like '[未ログイン][期限内/期限切れ/存在しない]存在するサブドメイン'
      it_behaves_like '[未ログイン][期限内/期限切れ/存在しない]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み]トークンが期限内' do
      include_context 'パスワードリセットトークン作成', true
      it_behaves_like '[ログイン中/削除予約済み][*]ベースドメイン'
      it_behaves_like '[ログイン中/削除予約済み][*]存在するサブドメイン'
      it_behaves_like '[ログイン中/削除予約済み][*]存在しないサブドメイン'
    end
    shared_examples_for '[未ログイン]トークンが期限切れ' do
      include_context 'パスワードリセットトークン作成', false
      it_behaves_like '[未ログイン][期限切れ/存在しない]ベースドメイン'
      it_behaves_like '[未ログイン][期限内/期限切れ/存在しない]存在するサブドメイン'
      it_behaves_like '[未ログイン][期限内/期限切れ/存在しない]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み]トークンが期限切れ' do
      include_context 'パスワードリセットトークン作成', false
      it_behaves_like '[ログイン中/削除予約済み][*]ベースドメイン'
      it_behaves_like '[ログイン中/削除予約済み][*]存在するサブドメイン'
      it_behaves_like '[ログイン中/削除予約済み][*]存在しないサブドメイン'
    end
    shared_examples_for '[未ログイン]トークンが存在しない' do
      let!(:reset_password_token) { NOT_TOKEN }
      it_behaves_like '[未ログイン][期限切れ/存在しない]ベースドメイン'
      it_behaves_like '[未ログイン][期限内/期限切れ/存在しない]存在するサブドメイン'
      it_behaves_like '[未ログイン][期限内/期限切れ/存在しない]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み]トークンが存在しない' do
      let!(:reset_password_token) { NOT_TOKEN }
      it_behaves_like '[ログイン中/削除予約済み][*]ベースドメイン'
      it_behaves_like '[ログイン中/削除予約済み][*]存在するサブドメイン'
      it_behaves_like '[ログイン中/削除予約済み][*]存在しないサブドメイン'
    end
    shared_examples_for '[未ログイン]トークンがない' do
      let!(:reset_password_token) { NO_TOKEN }
      it_behaves_like '[未ログイン][ない]ベースドメイン'
      it_behaves_like '[未ログイン][ない]存在するサブドメイン'
      it_behaves_like '[未ログイン][ない]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み]トークンがない' do
      let!(:reset_password_token) { NO_TOKEN }
      it_behaves_like '[ログイン中/削除予約済み][*]ベースドメイン'
      it_behaves_like '[ログイン中/削除予約済み][*]存在するサブドメイン'
      it_behaves_like '[ログイン中/削除予約済み][*]存在しないサブドメイン'
    end

    context '未ログイン' do
      it_behaves_like '[未ログイン]トークンが期限内'
      it_behaves_like '[未ログイン]トークンが期限切れ'
      it_behaves_like '[未ログイン]トークンが存在しない'
      it_behaves_like '[未ログイン]トークンがない'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[ログイン中/削除予約済み]トークンが期限内'
      it_behaves_like '[ログイン中/削除予約済み]トークンが期限切れ'
      it_behaves_like '[ログイン中/削除予約済み]トークンが存在しない'
      it_behaves_like '[ログイン中/削除予約済み]トークンがない'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it_behaves_like '[ログイン中/削除予約済み]トークンが期限内'
      it_behaves_like '[ログイン中/削除予約済み]トークンが期限切れ'
      it_behaves_like '[ログイン中/削除予約済み]トークンが存在しない'
      it_behaves_like '[ログイン中/削除予約済み]トークンがない'
    end
  end

  # PUT /users/password パスワード再設定(処理)
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  #   トークン: 期限内, 期限切れ, 存在しない, ない → データ作成
  #   有効なパラメータ, 無効なパラメータ → 事前にデータ作成
  #   ベースドメイン, 存在するサブドメイン, 存在しないサブドメイン → 事前にデータ作成
  describe 'PUT /update' do
    let!(:valid_attributes) { FactoryBot.attributes_for(:user) }
    let!(:invalid_attributes) { FactoryBot.attributes_for(:user, password: nil) }

    # テスト内容
    shared_examples_for 'OK' do
      it 'パスワードリセット送信日時がなしに変更される' do
        put user_password_path, params: { user: attributes.merge({ reset_password_token: reset_password_token }) }, headers: headers
        expect(User.find(@send_user.id).reset_password_sent_at).to be_nil
      end
    end
    shared_examples_for 'NG' do
      it 'パスワードリセット送信日時が変更されない' do
        put user_password_path, params: { user: attributes.merge({ reset_password_token: reset_password_token }) }, headers: headers
        expect(User.find(@send_user.id).reset_password_sent_at).to eq(@send_user.reset_password_sent_at)
      end
    end

    shared_examples_for 'ToOK' do
      it '成功ステータス' do
        put user_password_path, params: { user: attributes.merge({ reset_password_token: reset_password_token }) }, headers: headers
        expect(response).to be_successful
      end
    end
    shared_examples_for 'ToNot' do
      it '存在しないステータス' do
        put user_password_path, params: { user: attributes.merge({ reset_password_token: reset_password_token }) }, headers: headers
        expect(response).to be_not_found
      end
    end
    shared_examples_for 'ToTop' do |alert, notice|
      it 'トップページにリダイレクト' do
        put user_password_path, params: { user: attributes.merge({ reset_password_token: reset_password_token }) }, headers: headers
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end
    shared_examples_for 'ToNew' do |alert, notice|
      it 'パスワード再設定[メール送信]にリダイレクト' do
        put user_password_path, params: { user: attributes.merge({ reset_password_token: reset_password_token }) }, headers: headers
        expect(response).to redirect_to(new_user_password_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end

    # テストケース
    shared_examples_for '[未ログイン][期限内][有効]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'OK'
      it_behaves_like 'ToTop', nil, 'devise.passwords.updated'
    end
    shared_examples_for '[ログイン中/削除予約済み][期限内/期限切れ][有効]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'NG'
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン][期限切れ][有効]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'NG'
      it_behaves_like 'ToNew', 'activerecord.errors.models.user.attributes.reset_password_token.invalid', nil
    end
    shared_examples_for '[未ログイン][存在しない/ない][有効]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      # it_behaves_like 'NG' # Tips: トークンが存在しない為、送信日時がない
      it_behaves_like 'ToNew', 'activerecord.errors.models.user.attributes.reset_password_token.invalid', nil
    end
    shared_examples_for '[ログイン中/削除予約済み][存在しない/ない][有効]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      # it_behaves_like 'NG' # Tips: トークンが存在しない為、送信日時がない
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン][期限内][無効]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'NG'
      it_behaves_like 'ToOK' # Tips: 再入力
    end
    shared_examples_for '[ログイン中/削除予約済み][期限内/期限切れ][無効]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'NG'
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン][期限切れ][無効]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'NG'
      it_behaves_like 'ToNew', 'activerecord.errors.models.user.attributes.reset_password_token.invalid', nil
    end
    shared_examples_for '[未ログイン][存在しない/ない][無効]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      # it_behaves_like 'NG' # Tips: トークンが存在しない為、送信日時がない
      it_behaves_like 'ToNew', 'activerecord.errors.models.user.attributes.reset_password_token.invalid', nil
    end
    shared_examples_for '[ログイン中/削除予約済み][存在しない/ない][無効]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      # it_behaves_like 'NG' # Tips: トークンが存在しない為、送信日時がない
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン][期限内/期限切れ][*]存在するサブドメイン' do
      let!(:headers) { @space_header }
      it_behaves_like 'NG'
      it_behaves_like 'ToNot'
    end
    shared_examples_for '[ログイン中/削除予約済み][期限内/期限切れ][*]存在するサブドメイン' do
      let!(:headers) { @space_header }
      it_behaves_like 'NG'
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン][存在しない/ない][*]存在するサブドメイン' do
      let!(:headers) { @space_header }
      # it_behaves_like 'NG' # Tips: トークンが存在しない為、送信日時がない
      it_behaves_like 'ToNot'
    end
    shared_examples_for '[ログイン中/削除予約済み][存在しない/ない][*]存在するサブドメイン' do
      let!(:headers) { @space_header }
      # it_behaves_like 'NG' # Tips: トークンが存在しない為、送信日時がない
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン][期限内/期限切れ][*]存在しないサブドメイン' do
      let!(:headers) { NOT_SPACE_HEADER }
      it_behaves_like 'NG'
      it_behaves_like 'ToNot'
    end
    shared_examples_for '[ログイン中/削除予約済み][期限内/期限切れ][*]存在しないサブドメイン' do
      let!(:headers) { NOT_SPACE_HEADER }
      it_behaves_like 'NG'
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン][存在しない/ない][*]存在しないサブドメイン' do
      let!(:headers) { NOT_SPACE_HEADER }
      # it_behaves_like 'NG' # Tips: トークンが存在しない為、送信日時がない
      it_behaves_like 'ToNot'
    end
    shared_examples_for '[ログイン中/削除予約済み][存在しない/ない][*]存在しないサブドメイン' do
      let!(:headers) { NOT_SPACE_HEADER }
      # it_behaves_like 'NG' # Tips: トークンが存在しない為、送信日時がない
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
    end

    shared_examples_for '[未ログイン][期限内]有効なパラメータ' do
      let!(:attributes) { valid_attributes }
      it_behaves_like '[未ログイン][期限内][有効]ベースドメイン'
      it_behaves_like '[未ログイン][期限内/期限切れ][*]存在するサブドメイン'
      it_behaves_like '[未ログイン][期限内/期限切れ][*]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み][期限内/期限切れ]有効なパラメータ' do
      let!(:attributes) { valid_attributes }
      it_behaves_like '[ログイン中/削除予約済み][期限内/期限切れ][有効]ベースドメイン'
      it_behaves_like '[ログイン中/削除予約済み][期限内/期限切れ][*]存在するサブドメイン'
      it_behaves_like '[ログイン中/削除予約済み][期限内/期限切れ][*]存在しないサブドメイン'
    end
    shared_examples_for '[未ログイン][期限切れ]有効なパラメータ' do
      let!(:attributes) { valid_attributes }
      it_behaves_like '[未ログイン][期限切れ][有効]ベースドメイン'
      it_behaves_like '[未ログイン][期限内/期限切れ][*]存在するサブドメイン'
      it_behaves_like '[未ログイン][期限内/期限切れ][*]存在しないサブドメイン'
    end
    shared_examples_for '[未ログイン][存在しない/ない]有効なパラメータ' do
      let!(:attributes) { valid_attributes }
      it_behaves_like '[未ログイン][存在しない/ない][有効]ベースドメイン'
      it_behaves_like '[未ログイン][存在しない/ない][*]存在するサブドメイン'
      it_behaves_like '[未ログイン][存在しない/ない][*]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み][存在しない/ない]有効なパラメータ' do
      let!(:attributes) { valid_attributes }
      it_behaves_like '[ログイン中/削除予約済み][存在しない/ない][有効]ベースドメイン'
      it_behaves_like '[ログイン中/削除予約済み][存在しない/ない][*]存在するサブドメイン'
      it_behaves_like '[ログイン中/削除予約済み][存在しない/ない][*]存在しないサブドメイン'
    end
    shared_examples_for '[未ログイン][期限内]無効なパラメータ' do
      let!(:attributes) { invalid_attributes }
      it_behaves_like '[未ログイン][期限内][無効]ベースドメイン'
      it_behaves_like '[未ログイン][期限内/期限切れ][*]存在するサブドメイン'
      it_behaves_like '[未ログイン][期限内/期限切れ][*]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み][期限内/期限切れ]無効なパラメータ' do
      let!(:attributes) { invalid_attributes }
      it_behaves_like '[ログイン中/削除予約済み][期限内/期限切れ][無効]ベースドメイン'
      it_behaves_like '[ログイン中/削除予約済み][期限内/期限切れ][*]存在するサブドメイン'
      it_behaves_like '[ログイン中/削除予約済み][期限内/期限切れ][*]存在しないサブドメイン'
    end
    shared_examples_for '[未ログイン][期限切れ]無効なパラメータ' do
      let!(:attributes) { invalid_attributes }
      it_behaves_like '[未ログイン][期限切れ][無効]ベースドメイン'
      it_behaves_like '[未ログイン][期限内/期限切れ][*]存在するサブドメイン'
      it_behaves_like '[未ログイン][期限内/期限切れ][*]存在しないサブドメイン'
    end
    shared_examples_for '[未ログイン][存在しない/ない]無効なパラメータ' do
      let!(:attributes) { invalid_attributes }
      it_behaves_like '[未ログイン][存在しない/ない][無効]ベースドメイン'
      it_behaves_like '[未ログイン][存在しない/ない][*]存在するサブドメイン'
      it_behaves_like '[未ログイン][存在しない/ない][*]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み][存在しない/ない]無効なパラメータ' do
      let!(:attributes) { invalid_attributes }
      it_behaves_like '[ログイン中/削除予約済み][存在しない/ない][無効]ベースドメイン'
      it_behaves_like '[ログイン中/削除予約済み][存在しない/ない][*]存在するサブドメイン'
      it_behaves_like '[ログイン中/削除予約済み][存在しない/ない][*]存在しないサブドメイン'
    end

    shared_examples_for '[未ログイン]トークンが期限内' do
      include_context 'パスワードリセットトークン作成', true
      it_behaves_like '[未ログイン][期限内]有効なパラメータ'
      it_behaves_like '[未ログイン][期限内]無効なパラメータ'
    end
    shared_examples_for '[ログイン中/削除予約済み]トークンが期限内' do
      include_context 'パスワードリセットトークン作成', true
      it_behaves_like '[ログイン中/削除予約済み][期限内/期限切れ]有効なパラメータ'
      it_behaves_like '[ログイン中/削除予約済み][期限内/期限切れ]無効なパラメータ'
    end
    shared_examples_for '[未ログイン]トークンが期限切れ' do
      include_context 'パスワードリセットトークン作成', false
      it_behaves_like '[未ログイン][期限切れ]有効なパラメータ'
      it_behaves_like '[未ログイン][期限切れ]無効なパラメータ'
    end
    shared_examples_for '[ログイン中/削除予約済み]トークンが期限切れ' do
      include_context 'パスワードリセットトークン作成', false
      it_behaves_like '[ログイン中/削除予約済み][期限内/期限切れ]有効なパラメータ'
      it_behaves_like '[ログイン中/削除予約済み][期限内/期限切れ]無効なパラメータ'
    end
    shared_examples_for '[未ログイン]トークンが存在しない' do
      let!(:reset_password_token) { NOT_TOKEN }
      it_behaves_like '[未ログイン][存在しない/ない]有効なパラメータ'
      it_behaves_like '[未ログイン][存在しない/ない]無効なパラメータ'
    end
    shared_examples_for '[ログイン中/削除予約済み]トークンが存在しない' do
      let!(:reset_password_token) { NOT_TOKEN }
      it_behaves_like '[ログイン中/削除予約済み][存在しない/ない]有効なパラメータ'
      it_behaves_like '[ログイン中/削除予約済み][存在しない/ない]無効なパラメータ'
    end
    shared_examples_for '[未ログイン]トークンがない' do
      let!(:reset_password_token) { NO_TOKEN }
      it_behaves_like '[未ログイン][存在しない/ない]有効なパラメータ'
      it_behaves_like '[未ログイン][存在しない/ない]無効なパラメータ'
    end
    shared_examples_for '[ログイン中/削除予約済み]トークンがない' do
      let!(:reset_password_token) { NO_TOKEN }
      it_behaves_like '[ログイン中/削除予約済み][存在しない/ない]有効なパラメータ'
      it_behaves_like '[ログイン中/削除予約済み][存在しない/ない]無効なパラメータ'
    end

    context '未ログイン' do
      it_behaves_like '[未ログイン]トークンが期限内'
      it_behaves_like '[未ログイン]トークンが期限切れ'
      it_behaves_like '[未ログイン]トークンが存在しない'
      it_behaves_like '[未ログイン]トークンがない'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[ログイン中/削除予約済み]トークンが期限内'
      it_behaves_like '[ログイン中/削除予約済み]トークンが期限切れ'
      it_behaves_like '[ログイン中/削除予約済み]トークンが存在しない'
      it_behaves_like '[ログイン中/削除予約済み]トークンがない'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it_behaves_like '[ログイン中/削除予約済み]トークンが期限内'
      it_behaves_like '[ログイン中/削除予約済み]トークンが期限切れ'
      it_behaves_like '[ログイン中/削除予約済み]トークンが存在しない'
      it_behaves_like '[ログイン中/削除予約済み]トークンがない'
    end
  end
end
