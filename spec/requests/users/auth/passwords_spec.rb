require 'rails_helper'

RSpec.describe 'Users::Auth::Passwords', type: :request do
  # POST /users/auth/password パスワード再設定[メール送信](処理)
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  #   パラメータなし, 有効なパラメータ, 無効なパラメータ, ホワイトリストにないURL → 事前にデータ作成
  describe 'POST #create' do
    let!(:send_user) { FactoryBot.create(:user) }
    let!(:valid_params) { { email: send_user.email, redirect_url: "#{FRONT_SITE_URL}sign_in" } }
    let!(:invalid_params) { { email: nil, redirect_url: "#{FRONT_SITE_URL}sign_in" } }
    let!(:invalid_url_params) { { email: send_user.email, redirect_url: BAD_SITE_URL } }

    # テスト内容
    shared_examples_for 'OK' do
      it 'メールが送信される' do
        before_count = ActionMailer::Base.deliveries.count
        post create_user_auth_password_path, params: params, headers: headers
        expect(ActionMailer::Base.deliveries.count).to eq(before_count + 1) # パスワード再設定方法のお知らせ
      end
    end
    shared_examples_for 'NG' do
      it 'メールが送信されない' do
        before_count = ActionMailer::Base.deliveries.count
        post create_user_auth_password_path, params: params, headers: headers
        expect(ActionMailer::Base.deliveries.count).to eq(before_count)
      end
    end

    shared_examples_for 'ToOK' do # |alert, notice|
      it '成功ステータス・JSONデータ' do
        post create_user_auth_password_path, params: params, headers: headers
        expect(response).to be_successful

        response_json = JSON.parse(response.body)
        expect(response_json['success']).to eq(true)
        expect(response_json['errors']).to be_nil
        expect(response_json['message']).not_to be_nil
        # expect(response_json['message']).to be_nil

        # expect(response_json['alert']).to alert.present? ? eq(I18n.t(alert)) : be_nil
        # expect(response_json['notice']).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end
    shared_examples_for 'ToNG' do |alert, notice|
      it '失敗ステータス・JSONデータ' do
        post create_user_auth_password_path, params: params, headers: headers
        expect(response).to have_http_status(422)

        response_json = JSON.parse(response.body)
        expect(response_json['success']).to eq(false)
        expect(response_json['errors']).not_to be_nil
        expect(response_json['message']).to be_nil

        expect(response_json['alert']).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(response_json['notice']).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end
    shared_examples_for 'ToNG(401)' do
      it '失敗ステータス・JSONデータ' do
        post create_user_auth_password_path, params: params, headers: headers
        expect(response).to have_http_status(401)

        response_json = JSON.parse(response.body)
        expect(response_json['success']).to eq(false)
        expect(response_json['errors']).not_to be_nil
        expect(response_json['message']).to be_nil
      end
    end

    # テストケース
    shared_examples_for '[*]パラメータなし' do
      let!(:params) { nil }
      it_behaves_like 'NG'
      it_behaves_like 'ToNG', nil, nil
    end
    shared_examples_for '[未ログイン]有効なパラメータ' do
      let!(:params) { valid_params }
      it_behaves_like 'OK'
      it_behaves_like 'ToOK', nil, 'devise.passwords.send_instructions'
    end
    shared_examples_for '[ログイン中/削除予約済み]有効なパラメータ' do
      let!(:params) { valid_params }
      it_behaves_like 'OK'
      it_behaves_like 'ToOK', nil, nil
      # it_behaves_like 'NG'
      # it_behaves_like 'ToNG', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン]無効なパラメータ' do
      let!(:params) { invalid_params }
      it_behaves_like 'NG'
      it_behaves_like 'ToNG(401)'
      # it_behaves_like 'ToNG', nil, nil
    end
    shared_examples_for '[ログイン中/削除予約済み]無効なパラメータ' do
      let!(:params) { invalid_params }
      it_behaves_like 'NG'
      it_behaves_like 'ToNG(401)'
      # it_behaves_like 'ToNG', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[*]ホワイトリストにないURL' do
      let!(:params) { invalid_url_params }
      it_behaves_like 'NG'
      it_behaves_like 'ToNG', nil, nil
    end

    context '未ログイン' do
      let!(:headers) { nil }
      it_behaves_like '[*]パラメータなし'
      it_behaves_like '[未ログイン]有効なパラメータ'
      it_behaves_like '[未ログイン]無効なパラメータ'
      it_behaves_like '[*]ホワイトリストにないURL'
    end
    context 'ログイン中' do
      include_context 'authログイン処理'
      let!(:headers) { auth_headers }
      it_behaves_like '[*]パラメータなし'
      it_behaves_like '[ログイン中/削除予約済み]有効なパラメータ'
      it_behaves_like '[ログイン中/削除予約済み]無効なパラメータ'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'authログイン処理', true
      let!(:headers) { auth_headers }
      it_behaves_like '[*]パラメータなし'
      it_behaves_like '[ログイン中/削除予約済み]有効なパラメータ'
      it_behaves_like '[ログイン中/削除予約済み]無効なパラメータ'
      it_behaves_like '[*]ホワイトリストにないURL'
    end
  end

  # GET /users/auth/password パスワード再設定
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  #   トークン: 期限内, 期限切れ, 存在しない, ない → データ作成
  #   ＋リダイレクトURL: ある, ない, ホワイトリストにない
  describe 'GET #edit' do
    let!(:valid_redirect_url) { "#{FRONT_SITE_URL}sign_in" }
    let!(:invalid_redirect_url) { "#{BAD_SITE_URL}sign_in" }

    # テスト内容
    shared_examples_for 'BadURL' do
      it '[リダイレクトURLがない]エラーページにリダイレクト' do
        get edit_user_auth_password_path(reset_password_token: reset_password_token, redirect_url: nil)
        expect(response).to have_http_status(422)
        response_json = JSON.parse(response.body)
        expect(response_json['success']).to eq(false)
        expect(response_json['errors']).not_to be_nil
        # expect(response).to redirect_to('/reset_password_error.html?not')
      end
      it '[リダイレクトURLがホワイトリストにない]エラーページにリダイレクト' do
        get edit_user_auth_password_path(reset_password_token: reset_password_token, redirect_url: invalid_redirect_url)
        expect(response).to have_http_status(422)
        response_json = JSON.parse(response.body)
        expect(response_json['success']).to eq(false)
        expect(response_json['errors']).not_to be_nil
        # expect(response).to redirect_to('/reset_password_error.html?bad')
      end
    end

    shared_examples_for 'ToOK' do
      it '[リダイレクトURLがある]指定URL（成功パラメータ）にリダイレクト' do
        get edit_user_auth_password_path(reset_password_token: reset_password_token, redirect_url: valid_redirect_url)
        expect(response).to redirect_to("#{valid_redirect_url}?reset_password_token=#{reset_password_token}")
      end
      it_behaves_like 'BadURL'
    end
    shared_examples_for 'ToNG' do |alert, notice|
      it '[リダイレクトURLがある]指定URL（失敗パラメータ）にリダイレクト' do
        get edit_user_auth_password_path(reset_password_token: reset_password_token, redirect_url: valid_redirect_url)
        param = '?reset_password=false'
        param += "&alert=#{I18n.t(alert)}" if alert.present?
        param += "&notice=#{I18n.t(notice)}" if notice.present?
        expect(response).to redirect_to("#{valid_redirect_url}#{param}")
      end
      it_behaves_like 'BadURL'
    end

    # テストケース
    shared_examples_for '[未ログイン]トークンが期限内' do
      include_context 'パスワードリセットトークン作成', true
      it_behaves_like 'ToOK'
    end
    shared_examples_for '[ログイン中/削除予約済み]トークンが期限内' do
      include_context 'パスワードリセットトークン作成', true
      it_behaves_like 'ToOK'
      # it_behaves_like 'ToNG', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン]トークンが期限切れ' do
      include_context 'パスワードリセットトークン作成', false
      # Tips: ActionController::RoutingError: Not Found
      # it_behaves_like 'ToNG', 'activerecord.errors.models.user.attributes.reset_password_token.invalid', nil
    end
    shared_examples_for '[ログイン中/削除予約済み]トークンが期限切れ' do
      include_context 'パスワードリセットトークン作成', false
      # Tips: ActionController::RoutingError: Not Found
      # it_behaves_like 'ToNG', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン]トークンが存在しない' do
      let!(:reset_password_token) { NOT_TOKEN }
      # Tips: ActionController::RoutingError: Not Found
      # it_behaves_like 'ToNG', 'activerecord.errors.models.user.attributes.reset_password_token.invalid', nil
    end
    shared_examples_for '[ログイン中/削除予約済み]トークンが存在しない' do
      let!(:reset_password_token) { NOT_TOKEN }
      # Tips: ActionController::RoutingError: Not Found
      # it_behaves_like 'ToNG', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン]トークンがない' do
      let!(:reset_password_token) { NO_TOKEN }
      # Tips: ActionController::RoutingError: Not Found
      # it_behaves_like 'ToNG', 'devise.passwords.no_token', nil
    end
    shared_examples_for '[ログイン中/削除予約済み]トークンがない' do
      let!(:reset_password_token) { NO_TOKEN }
      # Tips: ActionController::RoutingError: Not Found
      # it_behaves_like 'ToNG', 'devise.failure.already_authenticated', nil
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

  # PUT(PATCH) /users/auth/password/update パスワード再設定(処理)
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  #   トークン: 期限内, 期限切れ, 存在しない, ない → データ作成
  #   パラメータなし, 有効なパラメータ, 無効なパラメータ → 事前にデータ作成
  describe 'PUT #update' do
    let!(:new_password) { Faker::Internet.password(min_length: 8) }
    shared_context '有効なパラメータ' do
      let!(:params) { { reset_password_token: reset_password_token, password: new_password, password_confirmation: new_password } }
    end
    shared_context '無効なパラメータ' do
      let!(:params) { { reset_password_token: reset_password_token, password: new_password, password_confirmation: nil } }
    end

    # テスト内容
    shared_examples_for 'OK' do
      it 'パスワードリセット送信日時がなしに変更される' do
        put update_user_auth_password_path, params: params, headers: headers
        expect(User.find(@send_user.id).reset_password_sent_at).to be_nil
      end
      it 'メールが送信される' do
        before_count = ActionMailer::Base.deliveries.count
        put update_user_auth_password_path, params: params, headers: headers
        expect(ActionMailer::Base.deliveries.count).to eq(before_count + 1) # パスワード変更完了のお知らせ
      end
    end
    shared_examples_for 'NG' do
      it 'パスワードリセット送信日時が変更されない' do
        put update_user_auth_password_path, params: params, headers: headers
        expect(User.find(@send_user.id).reset_password_sent_at).to eq(@send_user.reset_password_sent_at)
      end
      it 'メールが送信されない' do
        before_count = ActionMailer::Base.deliveries.count
        put update_user_auth_password_path, params: params, headers: headers
        expect(ActionMailer::Base.deliveries.count).to eq(before_count)
      end
    end

    shared_examples_for 'ToOK' do # |alert, notice|
      it '成功ステータス・JSONデータ' do
        put update_user_auth_password_path, params: params, headers: headers
        expect(response).to be_successful

        response_json = JSON.parse(response.body)
        expect(response_json['success']).to eq(true)
        expect(response_json['errors']).to be_nil
        expect(response_json['message']).not_to be_nil
        # expect(response_json['message']).to be_nil

        # expect(response_json['alert']).to alert.present? ? eq(I18n.t(alert)) : be_nil
        # expect(response_json['notice']).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end
    shared_examples_for 'ToNG' do # |alert, notice|
      it '失敗ステータス・JSONデータ' do
        put update_user_auth_password_path, params: params, headers: headers
        expect(response).to have_http_status(422)

        response_json = JSON.parse(response.body)
        expect(response_json['success']).to eq(false)
        expect(response_json['errors']).not_to be_nil
        expect(response_json['message']).to be_nil

        # expect(response_json['alert']).to alert.present? ? eq(I18n.t(alert)) : be_nil
        # expect(response_json['notice']).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end
    shared_examples_for 'ToNG(401)' do
      it '失敗ステータス・JSONデータ' do
        put update_user_auth_password_path, params: params, headers: headers
        expect(response).to have_http_status(401)

        response_json = JSON.parse(response.body)
        expect(response_json['success']).to eq(false)
        expect(response_json['errors']).not_to be_nil
        expect(response_json['message']).to be_nil
      end
    end

    # テストケース
    shared_examples_for '[未ログイン][期限内/期限切れ]パラメータなし' do
      let!(:params) { nil }
      it_behaves_like 'NG'
      it_behaves_like 'ToNG(401)'
      # it_behaves_like 'ToNG', nil, nil
    end
    shared_examples_for '[ログイン中/削除予約済み][期限内/期限切れ]パラメータなし' do
      let!(:params) { nil }
      it_behaves_like 'NG'
      it_behaves_like 'ToNG', nil, nil
    end
    shared_examples_for '[未ログイン][存在しない/ない]パラメータなし' do
      let!(:params) { nil }
      # it_behaves_like 'NG' # Tips: トークンが存在しない為、送信日時がない
      it_behaves_like 'ToNG(401)'
      # it_behaves_like 'ToNG', nil, nil
    end
    shared_examples_for '[ログイン中/削除予約済み][存在しない/ない]パラメータなし' do
      let!(:params) { nil }
      # it_behaves_like 'NG' # Tips: トークンが存在しない為、送信日時がない
      it_behaves_like 'ToNG', nil, nil
    end
    shared_examples_for '[未ログイン][期限内]有効なパラメータ' do
      include_context '有効なパラメータ'
      it_behaves_like 'OK'
      it_behaves_like 'ToOK', nil, 'devise.passwords.updated'
    end
    shared_examples_for '[ログイン中/削除予約済み][期限内/期限切れ]有効なパラメータ' do
      include_context '有効なパラメータ'
      it_behaves_like 'OK'
      it_behaves_like 'ToOK', nil, nil
      # it_behaves_like 'NG'
      # it_behaves_like 'ToNG', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン][期限切れ]有効なパラメータ' do
      include_context '有効なパラメータ'
      it_behaves_like 'OK'
      it_behaves_like 'ToOK', nil, nil
      # it_behaves_like 'NG'
      # it_behaves_like 'ToNG', 'activerecord.errors.models.user.attributes.reset_password_token.invalid', nil
    end
    shared_examples_for '[未ログイン][存在しない/ない]有効なパラメータ' do
      include_context '有効なパラメータ'
      # it_behaves_like 'NG' # Tips: トークンが存在しない為、送信日時がない
      it_behaves_like 'ToNG(401)'
      # it_behaves_like 'ToNG', 'activerecord.errors.models.user.attributes.reset_password_token.invalid', nil
    end
    shared_examples_for '[ログイン中/削除予約済み][存在しない/ない]有効なパラメータ' do
      include_context '有効なパラメータ'
      # it_behaves_like 'NG' # Tips: トークンが存在しない為、送信日時がない
      it_behaves_like 'ToNG(401)'
      # it_behaves_like 'ToNG', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン][期限内]無効なパラメータ' do
      include_context '無効なパラメータ'
      it_behaves_like 'NG'
      it_behaves_like 'ToNG', nil, nil
    end
    shared_examples_for '[ログイン中/削除予約済み][期限内/期限切れ]無効なパラメータ' do
      include_context '無効なパラメータ'
      it_behaves_like 'NG'
      it_behaves_like 'ToNG', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン][期限切れ]無効なパラメータ' do
      include_context '無効なパラメータ'
      it_behaves_like 'NG'
      it_behaves_like 'ToNG', 'activerecord.errors.models.user.attributes.reset_password_token.invalid', nil
    end
    shared_examples_for '[未ログイン][存在しない/ない]無効なパラメータ' do
      include_context '無効なパラメータ'
      # it_behaves_like 'NG' # Tips: トークンが存在しない為、送信日時がない
      it_behaves_like 'ToNG(401)'
      # it_behaves_like 'ToNG', 'activerecord.errors.models.user.attributes.reset_password_token.invalid', nil
    end
    shared_examples_for '[ログイン中/削除予約済み][存在しない/ない]無効なパラメータ' do
      include_context '無効なパラメータ'
      # it_behaves_like 'NG' # Tips: トークンが存在しない為、送信日時がない
      it_behaves_like 'ToNG(401)'
      # it_behaves_like 'ToNG', 'devise.failure.already_authenticated', nil
    end

    shared_examples_for '[未ログイン]トークンが期限内' do
      include_context 'パスワードリセットトークン作成', true
      it_behaves_like '[未ログイン][期限内/期限切れ]パラメータなし'
      it_behaves_like '[未ログイン][期限内]有効なパラメータ'
      it_behaves_like '[未ログイン][期限内]無効なパラメータ'
    end
    shared_examples_for '[ログイン中/削除予約済み]トークンが期限内' do
      include_context 'パスワードリセットトークン作成', true
      it_behaves_like '[ログイン中/削除予約済み][期限内/期限切れ]パラメータなし'
      it_behaves_like '[ログイン中/削除予約済み][期限内/期限切れ]有効なパラメータ'
      it_behaves_like '[ログイン中/削除予約済み][期限内/期限切れ]無効なパラメータ'
    end
    shared_examples_for '[未ログイン]トークンが期限切れ' do
      include_context 'パスワードリセットトークン作成', false
      it_behaves_like '[未ログイン][期限内/期限切れ]パラメータなし'
      it_behaves_like '[未ログイン][期限切れ]有効なパラメータ'
      it_behaves_like '[未ログイン][期限切れ]無効なパラメータ'
    end
    shared_examples_for '[ログイン中/削除予約済み]トークンが期限切れ' do
      include_context 'パスワードリセットトークン作成', false
      it_behaves_like '[ログイン中/削除予約済み][期限内/期限切れ]パラメータなし'
      it_behaves_like '[ログイン中/削除予約済み][期限内/期限切れ]有効なパラメータ'
      it_behaves_like '[ログイン中/削除予約済み][期限内/期限切れ]無効なパラメータ'
    end
    shared_examples_for '[未ログイン]トークンが存在しない' do
      let!(:reset_password_token) { NOT_TOKEN }
      it_behaves_like '[未ログイン][存在しない/ない]パラメータなし'
      it_behaves_like '[未ログイン][存在しない/ない]有効なパラメータ'
      it_behaves_like '[未ログイン][存在しない/ない]無効なパラメータ'
    end
    shared_examples_for '[ログイン中/削除予約済み]トークンが存在しない' do
      let!(:reset_password_token) { NOT_TOKEN }
      it_behaves_like '[ログイン中/削除予約済み][存在しない/ない]パラメータなし'
      it_behaves_like '[ログイン中/削除予約済み][存在しない/ない]有効なパラメータ'
      it_behaves_like '[ログイン中/削除予約済み][存在しない/ない]無効なパラメータ'
    end
    shared_examples_for '[未ログイン]トークンがない' do
      let!(:reset_password_token) { NO_TOKEN }
      it_behaves_like '[未ログイン][存在しない/ない]パラメータなし'
      it_behaves_like '[未ログイン][存在しない/ない]有効なパラメータ'
      it_behaves_like '[未ログイン][存在しない/ない]無効なパラメータ'
    end
    shared_examples_for '[ログイン中/削除予約済み]トークンがない' do
      let!(:reset_password_token) { NO_TOKEN }
      it_behaves_like '[ログイン中/削除予約済み][存在しない/ない]パラメータなし'
      it_behaves_like '[ログイン中/削除予約済み][存在しない/ない]有効なパラメータ'
      it_behaves_like '[ログイン中/削除予約済み][存在しない/ない]無効なパラメータ'
    end

    context '未ログイン' do
      let!(:headers) { nil }
      it_behaves_like '[未ログイン]トークンが期限内'
      it_behaves_like '[未ログイン]トークンが期限切れ'
      it_behaves_like '[未ログイン]トークンが存在しない'
      it_behaves_like '[未ログイン]トークンがない'
    end
    context 'ログイン中' do
      include_context 'authログイン処理'
      let!(:headers) { auth_headers }
      it_behaves_like '[ログイン中/削除予約済み]トークンが期限内'
      it_behaves_like '[ログイン中/削除予約済み]トークンが期限切れ'
      it_behaves_like '[ログイン中/削除予約済み]トークンが存在しない'
      it_behaves_like '[ログイン中/削除予約済み]トークンがない'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'authログイン処理', true
      let!(:headers) { auth_headers }
      it_behaves_like '[ログイン中/削除予約済み]トークンが期限内'
      it_behaves_like '[ログイン中/削除予約済み]トークンが期限切れ'
      it_behaves_like '[ログイン中/削除予約済み]トークンが存在しない'
      it_behaves_like '[ログイン中/削除予約済み]トークンがない'
    end
  end
end
