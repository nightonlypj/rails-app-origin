require 'rails_helper'

RSpec.describe 'Users::Auth::Passwords', type: :request do
  # POST /users/auth/password(.json) パスワード再設定API[メール送信](処理)
  # 前提条件
  #   Acceptヘッダがない
  # テストパターン
  #   URLの拡張子: ない, .json
  describe 'POST #create' do
    subject { post create_user_auth_password_path(format: subject_format) }

    # テストケース
    context 'URLの拡張子がない' do
      let(:subject_format) { nil }
      it_behaves_like 'To406'
    end
    context 'URLの拡張子が.json' do
      let(:subject_format) { :json }
      it_behaves_like 'To406'
    end
  end
  # 前提条件
  #   AcceptヘッダがJSON
  # テストパターン
  #   URLの拡張子: ない, .json
  #   未ログイン, ログイン中, APIログイン中
  #   パラメータなし, 有効なパラメータ（未ロック, ロック中, メール未確認）, 無効なパラメータ, URLがない, URLがホワイトリストにない
  describe 'POST #create(json)' do
    subject { post create_user_auth_password_path(format: subject_format), params: attributes, headers: auth_headers.merge(ACCEPT_JSON) }
    let(:send_user_unlocked)    { FactoryBot.create(:user) }
    let(:send_user_locked)      { FactoryBot.create(:user_locked) }
    let(:send_user_unconfirmed) { FactoryBot.create(:user_unconfirmed) }
    let(:not_user)              { FactoryBot.attributes_for(:user) }
    let(:valid_attributes)       { { email: send_user.email, redirect_url: FRONT_SITE_URL } }
    let(:invalid_attributes)     { { email: not_user[:email], redirect_url: FRONT_SITE_URL } }
    let(:invalid_nil_attributes) { { email: send_user_unlocked.email, redirect_url: nil } }
    let(:invalid_bad_attributes) { { email: send_user_unlocked.email, redirect_url: BAD_SITE_URL } }

    # テスト内容
    shared_examples_for 'OK' do
      it 'メールが送信される' do
        subject
        expect(ActionMailer::Base.deliveries.count).to eq(1)
        expect(ActionMailer::Base.deliveries[0].subject).to eq(get_subject('devise.mailer.reset_password_instructions.subject')) # パスワード再設定方法のお知らせ
      end
    end
    shared_examples_for 'NG' do
      it 'メールが送信されない' do
        expect { subject }.to change(ActionMailer::Base.deliveries, :count).by(0)
      end
    end

    shared_examples_for 'ToOK' do
      it 'HTTPステータスが200。対象項目が一致する' do
        is_expected.to eq(200)
        expect(JSON.parse(response.body)['success']).to eq(true)
      end
    end
    shared_examples_for 'ToNG' do |code|
      it "HTTPステータスが#{code}。対象項目が一致する" do
        is_expected.to eq(code) # 方針(優先順): 401: ログイン中, 400:パラメータなし, 422: 無効なパラメータ・状態
        expect(JSON.parse(response.body)['success']).to eq(false)
      end
    end
    shared_examples_for 'ToMsg' do |error_class, errors_count, error_msg, message, alert, notice|
      it '対象のメッセージと一致する。認証ヘッダがない' do
        subject
        response_json = JSON.parse(response.body)
        expect(response_json['errors'].to_s).to error_msg.present? ? include(I18n.t(error_msg)) : be_blank
        expect(response_json['errors'].class).to eq(error_class) # 方針: バリデーション(Hash)のみ、他はalertへ
        expect(response_json['errors']&.count).to errors_count.positive? ? eq(errors_count) : be_nil
        expect(response_json['message']).to message.present? ? eq(I18n.t(message)) : be_nil # 方針: 廃止して、noticeへ

        expect(response_json['alert']).to alert.present? ? eq(I18n.t(alert)) : be_nil # 方針: 追加
        expect(response_json['notice']).to notice.present? ? eq(I18n.t(notice)) : be_nil # 方針: 追加

        expect(response.header['uid']).to be_nil
        expect(response.header['client']).to be_nil
        expect(response.header['access-token']).to be_nil
      end
    end

    # テストケース
    shared_examples_for '[未ログイン/ログイン中]パラメータなし' do
      let(:attributes) { nil }
      it_behaves_like 'NG'
      it_behaves_like 'ToNG', 422
      # it_behaves_like 'ToNG', 400
      it_behaves_like 'ToMsg', Array, 1, 'devise_token_auth.passwords.not_allowed_redirect_url', nil, nil, nil
      # it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'errors.messages.validate_password_params', nil
    end
    shared_examples_for '[APIログイン中]パラメータなし' do
      let(:attributes) { nil }
      it_behaves_like 'NG'
      it_behaves_like 'ToNG', 422
      # it_behaves_like 'ToNG', 401
      it_behaves_like 'ToMsg', Array, 1, 'devise_token_auth.passwords.not_allowed_redirect_url', nil, nil, nil
      # it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン/ログイン中]有効なパラメータ（未ロック）' do
      let(:send_user)  { send_user_unlocked }
      let(:attributes) { valid_attributes }
      it_behaves_like 'OK'
      it_behaves_like 'ToOK', nil, 'devise.passwords.send_instructions'
      it_behaves_like 'ToMsg', NilClass, 0, nil, 'devise_token_auth.passwords.sended', nil, nil
      # it_behaves_like 'ToMsg', NilClass, 0, nil, nil, nil, 'devise_token_auth.passwords.sended'
    end
    shared_examples_for '[APIログイン中]有効なパラメータ（未ロック）' do
      let(:send_user)  { send_user_unlocked }
      let(:attributes) { valid_attributes }
      it_behaves_like 'OK'
      # it_behaves_like 'NG'
      it_behaves_like 'ToOK'
      # it_behaves_like 'ToNG', 401
      it_behaves_like 'ToMsg', NilClass, 0, nil, 'devise_token_auth.passwords.sended', nil, nil
      # it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン/ログイン中]有効なパラメータ（ロック中）' do # Tips: ロック中も出来ても良さそう
      let(:send_user)  { send_user_locked }
      let(:attributes) { valid_attributes }
      it_behaves_like 'OK'
      it_behaves_like 'ToOK', nil, 'devise.passwords.send_instructions'
      it_behaves_like 'ToMsg', NilClass, 0, nil, 'devise_token_auth.passwords.sended', nil, nil
      # it_behaves_like 'ToMsg', NilClass, 0, nil, nil, nil, 'devise_token_auth.passwords.sended'
    end
    shared_examples_for '[APIログイン中]有効なパラメータ（ロック中）' do
      let(:send_user)  { send_user_locked }
      let(:attributes) { valid_attributes }
      it_behaves_like 'OK'
      # it_behaves_like 'NG'
      it_behaves_like 'ToOK'
      # it_behaves_like 'ToNG', 401
      it_behaves_like 'ToMsg', NilClass, 0, nil, 'devise_token_auth.passwords.sended', nil, nil
      # it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン/ログイン中]有効なパラメータ（メール未確認）' do # Tips: メール未確認も出来ても良さそう
      let(:send_user)  { send_user_unconfirmed }
      let(:attributes) { valid_attributes }
      it_behaves_like 'OK'
      it_behaves_like 'ToOK', nil, 'devise.passwords.send_instructions'
      it_behaves_like 'ToMsg', NilClass, 0, nil, 'devise_token_auth.passwords.sended', nil, nil
      # it_behaves_like 'ToMsg', NilClass, 0, nil, nil, nil, 'devise_token_auth.passwords.sended'
    end
    shared_examples_for '[APIログイン中]有効なパラメータ（メール未確認）' do
      let(:send_user)  { send_user_unconfirmed }
      let(:attributes) { valid_attributes }
      it_behaves_like 'OK'
      # it_behaves_like 'NG'
      it_behaves_like 'ToOK'
      # it_behaves_like 'ToNG', 401
      it_behaves_like 'ToMsg', NilClass, 0, nil, 'devise_token_auth.passwords.sended', nil, nil
      # it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン/ログイン中]無効なパラメータ' do
      let(:attributes) { invalid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToNG', 404
      # it_behaves_like 'ToNG', 422
      it_behaves_like 'ToMsg', Array, 1, 'devise_token_auth.passwords.user_not_found', nil, nil, nil
      # it_behaves_like 'ToMsg', Hash, 2, 'devise_token_auth.passwords.user_not_found', nil, 'errors.messages.not_saved.one', nil
    end
    shared_examples_for '[APIログイン中]無効なパラメータ' do
      let(:attributes) { invalid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToNG', 404
      # it_behaves_like 'ToNG', 401
      it_behaves_like 'ToMsg', Array, 1, 'devise_token_auth.passwords.user_not_found', nil, nil, nil
      # it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン/ログイン中]URLがない' do
      let(:attributes) { invalid_nil_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToNG', 401
      # it_behaves_like 'ToNG', 422
      it_behaves_like 'ToMsg', Array, 1, 'devise_token_auth.passwords.missing_redirect_url', nil, nil, nil
      # it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise_token_auth.passwords.missing_redirect_url', nil
    end
    shared_examples_for '[APIログイン中]URLがない' do
      let(:attributes) { invalid_nil_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToNG', 401
      it_behaves_like 'ToMsg', Array, 1, 'devise_token_auth.passwords.missing_redirect_url', nil, nil, nil
      # it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン/ログイン中]URLがホワイトリストにない' do
      let(:attributes) { invalid_bad_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToNG', 422
      it_behaves_like 'ToMsg', Array, 1, 'devise_token_auth.passwords.not_allowed_redirect_url', nil, nil, nil
      # it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise_token_auth.passwords.not_allowed_redirect_url', nil
    end
    shared_examples_for '[APIログイン中]URLがホワイトリストにない' do
      let(:attributes) { invalid_bad_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToNG', 422
      # it_behaves_like 'ToNG', 401
      it_behaves_like 'ToMsg', Array, 1, 'devise_token_auth.passwords.not_allowed_redirect_url', nil, nil, nil
      # it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise.failure.already_authenticated', nil
    end

    shared_examples_for '未ログイン' do
      include_context '未ログイン処理'
      it_behaves_like '[未ログイン/ログイン中]パラメータなし'
      it_behaves_like '[未ログイン/ログイン中]有効なパラメータ（未ロック）'
      it_behaves_like '[未ログイン/ログイン中]有効なパラメータ（ロック中）'
      it_behaves_like '[未ログイン/ログイン中]有効なパラメータ（メール未確認）'
      it_behaves_like '[未ログイン/ログイン中]無効なパラメータ'
      it_behaves_like '[未ログイン/ログイン中]URLがない'
      it_behaves_like '[未ログイン/ログイン中]URLがホワイトリストにない'
    end
    shared_examples_for 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[未ログイン/ログイン中]パラメータなし'
      it_behaves_like '[未ログイン/ログイン中]有効なパラメータ（未ロック）'
      it_behaves_like '[未ログイン/ログイン中]有効なパラメータ（ロック中）'
      it_behaves_like '[未ログイン/ログイン中]有効なパラメータ（メール未確認）'
      it_behaves_like '[未ログイン/ログイン中]無効なパラメータ'
      it_behaves_like '[未ログイン/ログイン中]URLがない'
      it_behaves_like '[未ログイン/ログイン中]URLがホワイトリストにない'
    end
    shared_examples_for 'APIログイン中' do
      include_context 'APIログイン処理'
      it_behaves_like '[APIログイン中]パラメータなし'
      it_behaves_like '[APIログイン中]有効なパラメータ（未ロック）'
      it_behaves_like '[APIログイン中]有効なパラメータ（ロック中）'
      it_behaves_like '[APIログイン中]有効なパラメータ（メール未確認）'
      it_behaves_like '[APIログイン中]無効なパラメータ'
      it_behaves_like '[APIログイン中]URLがない'
      it_behaves_like '[APIログイン中]URLがホワイトリストにない'
    end

    context 'URLの拡張子がない' do
      let(:subject_format) { nil }
      it_behaves_like '未ログイン'
      it_behaves_like 'ログイン中'
      it_behaves_like 'APIログイン中'
    end
    context 'URLの拡張子が.json' do
      let(:subject_format) { :json }
      it_behaves_like '未ログイン'
      it_behaves_like 'ログイン中'
      it_behaves_like 'APIログイン中'
    end
  end

  # GET /users/auth/password パスワード再設定
  # 前提条件
  #   以外（URLの拡張子がない, Acceptヘッダがない）
  # テストパターン
  #   URLの拡張子: ない, .json
  #   Acceptヘッダ: ない, JSON
  describe 'GET #edit(json)' do
    subject { get edit_user_auth_password_path(format: subject_format), headers: accept_headers }

    # テストケース
    context 'URLの拡張子がない, AcceptヘッダがJSON' do
      let(:subject_format) { nil }
      let(:accept_headers) { ACCEPT_JSON }
      it_behaves_like 'To406'
    end
    context 'URLの拡張子が.json, Acceptヘッダがない' do
      let(:subject_format) { :json }
      let(:accept_headers) { nil }
      it_behaves_like 'To406'
    end
    context 'URLの拡張子が.json, AcceptヘッダがJSON' do
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_JSON }
      it_behaves_like 'To406'
    end
  end
  # 前提条件
  #   URLの拡張子がない, Acceptヘッダがない
  # テストパターン
  #   未ログイン, ログイン中, APIログイン中
  #   トークン: 期限内（未ロック, ロック中, メール未確認）, 期限切れ, 存在しない, ない, 空
  #   ＋リダイレクトURL: ある, ない, ホワイトリストにない
  describe 'GET #edit' do
    subject { get edit_user_auth_password_path(reset_password_token: reset_password_token, redirect_url: redirect_url), headers: auth_headers }

    # テスト内容
    shared_examples_for 'ToOK' do
      let(:redirect_url) { FRONT_SITE_URL }
      it '指定URL（成功パラメータ）にリダイレクトする' do
        is_expected.to redirect_to("#{FRONT_SITE_URL}?reset_password_token=#{reset_password_token}")
      end
    end
    shared_examples_for 'ToNG' do |alert, notice|
      let(:redirect_url) { FRONT_SITE_URL }
      it '指定URL（失敗パラメータ）にリダイレクトする' do
        param = '?reset_password=false'
        param += "&alert=#{I18n.t(alert)}" if alert.present?
        param += "&notice=#{I18n.t(notice)}" if notice.present?
        is_expected.to redirect_to("#{FRONT_SITE_URL}#{param}")
      end
    end

    shared_examples_for 'リダイレクトURLがない' do
      let(:redirect_url) { nil }
      it 'HTTPステータスが422。対象項目が一致する' do
        # it 'エラーページにリダイレクトする' do
        is_expected.to eq(422)
        response_json = JSON.parse(response.body)
        expect(response_json['success']).to eq(false)
        expect(response_json['errors']).not_to be_nil
        # is_expected.to redirect_to('/reset_password_error.html?not')
      end
    end
    shared_examples_for 'リダイレクトURLがホワイトリストにない' do
      let(:redirect_url) { BAD_SITE_URL }
      it 'HTTPステータスが422。対象項目が一致する' do
        # it 'エラーページにリダイレクトする' do
        is_expected.to eq(422)
        response_json = JSON.parse(response.body)
        expect(response_json['success']).to eq(false)
        expect(response_json['errors']).not_to be_nil
        # is_expected.to redirect_to('/reset_password_error.html?bad')
      end
    end

    # テストケース
    shared_examples_for '[未ログイン/APIログイン中]トークンが期限内（未ロック）' do
      include_context 'パスワードリセットトークン作成', true
      it_behaves_like 'ToOK'
      it_behaves_like 'リダイレクトURLがない'
      it_behaves_like 'リダイレクトURLがホワイトリストにない'
    end
    shared_examples_for '[ログイン中]トークンが期限内（未ロック）' do
      include_context 'パスワードリセットトークン作成', true
      it_behaves_like 'ToOK'
      # it_behaves_like 'ToNG', 'devise.failure.already_authenticated', nil
      it_behaves_like 'リダイレクトURLがない'
      it_behaves_like 'リダイレクトURLがホワイトリストにない'
    end
    shared_examples_for '[未ログイン/APIログイン中]トークンが期限内（ロック中）' do # Tips: ロック中も出来ても良さそう
      include_context 'パスワードリセットトークン作成', true, true
      it_behaves_like 'ToOK'
      it_behaves_like 'リダイレクトURLがない'
      it_behaves_like 'リダイレクトURLがホワイトリストにない'
    end
    shared_examples_for '[ログイン中]トークンが期限内（ロック中）' do
      include_context 'パスワードリセットトークン作成', true, true
      it_behaves_like 'ToOK'
      # it_behaves_like 'ToNG', 'devise.failure.already_authenticated', nil
      it_behaves_like 'リダイレクトURLがない'
      it_behaves_like 'リダイレクトURLがホワイトリストにない'
    end
    shared_examples_for '[未ログイン/APIログイン中]トークンが期限内（メール未確認）' do # Tips: メール未確認も出来ても良さそう
      include_context 'パスワードリセットトークン作成', true, false, true
      it_behaves_like 'ToOK'
      it_behaves_like 'リダイレクトURLがない'
      it_behaves_like 'リダイレクトURLがホワイトリストにない'
    end
    shared_examples_for '[ログイン中]トークンが期限内（メール未確認）' do
      include_context 'パスワードリセットトークン作成', true, false, true
      it_behaves_like 'ToOK'
      # it_behaves_like 'ToNG', 'devise.failure.already_authenticated', nil
      it_behaves_like 'リダイレクトURLがない'
      it_behaves_like 'リダイレクトURLがホワイトリストにない'
    end
    shared_examples_for '[未ログイン/APIログイン中]トークンが期限切れ' do
      include_context 'パスワードリセットトークン作成', false
      # Tips: ActionController::RoutingError: Not Found
      # it_behaves_like 'ToNG', 'activerecord.errors.models.user.attributes.reset_password_token.invalid', nil
      it_behaves_like 'リダイレクトURLがない'
      it_behaves_like 'リダイレクトURLがホワイトリストにない'
    end
    shared_examples_for '[ログイン中]トークンが期限切れ' do
      include_context 'パスワードリセットトークン作成', false
      # Tips: ActionController::RoutingError: Not Found
      # it_behaves_like 'ToNG', 'devise.failure.already_authenticated', nil
      it_behaves_like 'リダイレクトURLがない'
      it_behaves_like 'リダイレクトURLがホワイトリストにない'
    end
    shared_examples_for '[未ログイン/APIログイン中]トークンが存在しない' do
      let(:reset_password_token) { NOT_TOKEN }
      # Tips: ActionController::RoutingError: Not Found
      # it_behaves_like 'ToNG', 'activerecord.errors.models.user.attributes.reset_password_token.invalid', nil
      it_behaves_like 'リダイレクトURLがない'
      it_behaves_like 'リダイレクトURLがホワイトリストにない'
    end
    shared_examples_for '[ログイン中]トークンが存在しない' do
      let(:reset_password_token) { NOT_TOKEN }
      # Tips: ActionController::RoutingError: Not Found
      # it_behaves_like 'ToNG', 'devise.failure.already_authenticated', nil
      it_behaves_like 'リダイレクトURLがない'
      it_behaves_like 'リダイレクトURLがホワイトリストにない'
    end
    shared_examples_for '[未ログイン/APIログイン中]トークンがない' do
      let(:reset_password_token) { nil }
      # Tips: ActionController::RoutingError: Not Found
      # it_behaves_like 'ToNG', 'devise.passwords.no_token', nil
      it_behaves_like 'リダイレクトURLがない'
      it_behaves_like 'リダイレクトURLがホワイトリストにない'
    end
    shared_examples_for '[ログイン中]トークンがない' do
      let(:reset_password_token) { nil }
      # Tips: ActionController::RoutingError: Not Found
      # it_behaves_like 'ToNG', 'devise.failure.already_authenticated', nil
      it_behaves_like 'リダイレクトURLがない'
      it_behaves_like 'リダイレクトURLがホワイトリストにない'
    end
    shared_examples_for '[未ログイン/APIログイン中]トークンが空' do
      let(:reset_password_token) { '' }
      # Tips: ActionController::RoutingError: Not Found
      # it_behaves_like 'ToNG', 'devise.passwords.no_token', nil
      it_behaves_like 'リダイレクトURLがない'
      it_behaves_like 'リダイレクトURLがホワイトリストにない'
    end
    shared_examples_for '[ログイン中]トークンが空' do
      let(:reset_password_token) { '' }
      # Tips: ActionController::RoutingError: Not Found
      # it_behaves_like 'ToNG', 'devise.failure.already_authenticated', nil
      it_behaves_like 'リダイレクトURLがない'
      it_behaves_like 'リダイレクトURLがホワイトリストにない'
    end

    context '未ログイン' do
      include_context '未ログイン処理'
      it_behaves_like '[未ログイン/APIログイン中]トークンが期限内（未ロック）'
      it_behaves_like '[未ログイン/APIログイン中]トークンが期限内（ロック中）'
      it_behaves_like '[未ログイン/APIログイン中]トークンが期限内（メール未確認）'
      it_behaves_like '[未ログイン/APIログイン中]トークンが期限切れ'
      it_behaves_like '[未ログイン/APIログイン中]トークンが存在しない'
      it_behaves_like '[未ログイン/APIログイン中]トークンがない'
      it_behaves_like '[未ログイン/APIログイン中]トークンが空'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[ログイン中]トークンが期限内（未ロック）'
      it_behaves_like '[ログイン中]トークンが期限内（ロック中）'
      it_behaves_like '[ログイン中]トークンが期限内（メール未確認）'
      it_behaves_like '[ログイン中]トークンが期限切れ'
      it_behaves_like '[ログイン中]トークンが存在しない'
      it_behaves_like '[ログイン中]トークンがない'
      it_behaves_like '[ログイン中]トークンが空'
    end
    context 'APIログイン中' do
      include_context 'APIログイン処理'
      it_behaves_like '[未ログイン/APIログイン中]トークンが期限内（未ロック）'
      it_behaves_like '[未ログイン/APIログイン中]トークンが期限内（ロック中）'
      it_behaves_like '[未ログイン/APIログイン中]トークンが期限内（メール未確認）'
      it_behaves_like '[未ログイン/APIログイン中]トークンが期限切れ'
      it_behaves_like '[未ログイン/APIログイン中]トークンが存在しない'
      it_behaves_like '[未ログイン/APIログイン中]トークンがない'
      it_behaves_like '[未ログイン/APIログイン中]トークンが空'
    end
  end

  # PUT(PATCH) /users/auth/password/update(.json) パスワード再設定API(処理)
  # 前提条件
  #   Acceptヘッダがない
  # テストパターン
  #   URLの拡張子: ない, .json
  describe 'PUT #update' do
    subject { put update_user_auth_password_path(format: subject_format) }

    # テストケース
    context 'URLの拡張子がない' do
      let(:subject_format) { nil }
      it_behaves_like 'To406'
    end
    context 'URLの拡張子が.json' do
      let(:subject_format) { :json }
      it_behaves_like 'To406'
    end
  end
  # 前提条件
  #   AcceptヘッダがJSON
  # テストパターン
  #   URLの拡張子: ない, .json
  #   未ログイン, ログイン中, APIログイン中
  #   トークン: 期限内（未ロック, ロック中, メール未確認）, 期限切れ, 存在しない, ない, 空
  #   パラメータなし, 有効なパラメータ, 無効なパラメータ
  describe 'PUT #update(json)' do
    subject { put update_user_auth_password_path, params: attributes, headers: auth_headers.merge(ACCEPT_JSON) }
    let(:new_password) { Faker::Internet.password(min_length: 8) }
    let(:valid_attributes)   { { reset_password_token: reset_password_token, password: new_password, password_confirmation: new_password } }
    let(:invalid_attributes) { { reset_password_token: reset_password_token, password: new_password, password_confirmation: nil } }

    # テスト内容
    shared_examples_for 'OK' do |check_confirmed = false|
      let!(:start_time) { Time.current.floor }
      it "パスワードリセット送信日時がなし#{'・メールアドレス確認日時が現在日時' if check_confirmed}に変更される。メールが送信される" do
        subject
        expect(User.find(send_user.id).reset_password_sent_at).to be_nil
        expect(User.find(send_user.id).confirmed_at).to be_between(start_time, Time.current) if check_confirmed

        expect(ActionMailer::Base.deliveries.count).to eq(1)
        expect(ActionMailer::Base.deliveries[0].subject).to eq(get_subject('devise.mailer.password_change.subject')) # パスワード変更完了のお知らせ
      end
    end
    shared_examples_for 'NG' do
      it 'パスワードリセット送信日時が変更されない。メールが送信されない' do
        subject
        expect(User.find(send_user.id).reset_password_sent_at).to eq(send_user.reset_password_sent_at)

        expect(ActionMailer::Base.deliveries.count).to eq(0)
      end
    end

    shared_examples_for 'ToOK' do
      it 'HTTPステータスが200。対象項目が一致する。認証ヘッダがある' do
        is_expected.to eq(200)
        expect(JSON.parse(response.body)['success']).to eq(true)

        expect(response.header['uid']).not_to be_nil
        expect(response.header['client']).not_to be_nil
        expect(response.header['access-token']).not_to be_nil
      end
    end
    shared_examples_for 'ToNG' do |code, uid, client, token|
      it "HTTPステータスが#{code}。対象項目が一致する。認証ヘッダがない" do
        is_expected.to eq(code) # 方針(優先順): 401: ログイン中, 400:パラメータなし, 422: 無効なパラメータ・状態
        expect(JSON.parse(response.body)['success']).to eq(false)

        expect(response.header['uid'].present?).to eq(uid)
        expect(response.header['client'].present?).to eq(client)
        expect(response.header['access-token'].present?).to eq(token)
      end
    end
    shared_examples_for 'ToMsg' do |error_class, errors_count, error_msg, message, alert, notice|
      it '対象のメッセージと一致する' do
        subject
        response_json = JSON.parse(response.body)
        msg = error_msg == 'Unauthorized' ? error_msg : I18n.t(error_msg)
        expect(response_json['errors'].to_s).to error_msg.present? ? include(msg) : be_blank
        expect(response_json['errors'].class).to eq(error_class) # 方針: バリデーション(Hash)のみ、他はalertへ
        expect(response_json['errors']&.count).to errors_count.positive? ? eq(errors_count) : be_nil
        expect(response_json['message']).to message.present? ? eq(I18n.t(message)) : be_nil # 方針: 廃止して、noticeへ

        expect(response_json['alert']).to alert.present? ? eq(I18n.t(alert)) : be_nil # 方針: 追加
        expect(response_json['notice']).to notice.present? ? eq(I18n.t(notice)) : be_nil # 方針: 追加
      end
    end

    # テストケース
    shared_examples_for '[未ログイン/ログイン中][期限内/期限切れ]パラメータなし' do
      let(:attributes) { nil }
      it_behaves_like 'NG'
      it_behaves_like 'ToNG', 401, false, false, false
      # it_behaves_like 'ToNG', 400, false, false, false
      it_behaves_like 'ToMsg', Array, 1, 'Unauthorized', nil, nil, nil
      # it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'errors.messages.validate_password_params', nil
    end
    shared_examples_for '[APIログイン中][期限内/期限切れ]パラメータなし' do
      let(:attributes) { nil }
      it_behaves_like 'NG'
      it_behaves_like 'ToNG', 422, true, true, false
      # it_behaves_like 'ToNG', 401, true, true, true
      it_behaves_like 'ToMsg', Array, 1, 'devise_token_auth.passwords.missing_passwords', nil, nil, nil
      # it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン/ログイン中][存在しない/ない/空]パラメータなし' do
      let(:attributes) { nil }
      # it_behaves_like 'NG' # Tips: トークンが存在しない為、送信日時がない
      it_behaves_like 'ToNG', 401, false, false, false
      # it_behaves_like 'ToNG', 400, false, false, false
      it_behaves_like 'ToMsg', Array, 1, 'Unauthorized', nil, nil, nil
      # it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'errors.messages.validate_password_params', nil
    end
    shared_examples_for '[APIログイン中][存在しない/ない/空]パラメータなし' do
      let(:attributes) { nil }
      # it_behaves_like 'NG' # Tips: トークンが存在しない為、送信日時がない
      it_behaves_like 'ToNG', 422, true, true, false
      # it_behaves_like 'ToNG', 401, true, true, true
      it_behaves_like 'ToMsg', Array, 1, 'devise_token_auth.passwords.missing_passwords', nil, nil, nil
      # it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン/ログイン中][期限内]有効なパラメータ' do
      let(:attributes) { valid_attributes }
      it_behaves_like 'OK'
      it_behaves_like 'ToOK'
      it_behaves_like 'ToMsg', NilClass, 0, nil, 'devise_token_auth.passwords.successfully_updated', nil, nil
      # it_behaves_like 'ToMsg', NilClass, 0, nil, nil, nil, 'devise_token_auth.passwords.successfully_updated'
    end
    shared_examples_for '[未ログイン/ログイン中][期限内（メール未確認）]有効なパラメータ' do
      let(:attributes) { valid_attributes }
      it_behaves_like 'OK'
      # it_behaves_like 'OK', true # Tips: 確認済みに変更したい
      it_behaves_like 'ToOK'
      it_behaves_like 'ToMsg', NilClass, 0, nil, 'devise_token_auth.passwords.successfully_updated', nil, nil
      # it_behaves_like 'ToMsg', NilClass, 0, nil, nil, nil, 'devise_token_auth.passwords.successfully_updated'
    end
    shared_examples_for '[APIログイン中][期限内/期限切れ]有効なパラメータ' do
      let(:attributes) { valid_attributes }
      it_behaves_like 'OK'
      # it_behaves_like 'NG'
      it_behaves_like 'ToOK'
      # it_behaves_like 'ToNG', 401, true, true, true
      it_behaves_like 'ToMsg', NilClass, 0, nil, 'devise_token_auth.passwords.successfully_updated', nil, nil
      # it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン/ログイン中][期限切れ]有効なパラメータ' do
      let(:attributes) { valid_attributes }
      it_behaves_like 'OK'
      # it_behaves_like 'NG'
      it_behaves_like 'ToOK'
      # it_behaves_like 'ToNG', 422, false, false, false
      it_behaves_like 'ToMsg', NilClass, 0, nil, 'devise_token_auth.passwords.successfully_updated', nil, nil
      # it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'activerecord.errors.models.user.attributes.reset_password_token.invalid', nil
    end
    shared_examples_for '[未ログイン/ログイン中][存在しない/ない/空]有効なパラメータ' do
      let(:attributes) { valid_attributes }
      # it_behaves_like 'NG' # Tips: トークンが存在しない為、送信日時がない
      it_behaves_like 'ToNG', 401, false, false, false
      # it_behaves_like 'ToNG', 422, false, false, false
      it_behaves_like 'ToMsg', Array, 1, 'Unauthorized', nil, nil, nil
      # it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'activerecord.errors.models.user.attributes.reset_password_token.invalid', nil
    end
    shared_examples_for '[APIログイン中][存在しない/空]有効なパラメータ' do
      let(:attributes) { valid_attributes }
      # it_behaves_like 'NG' # Tips: トークンが存在しない為、送信日時がない
      it_behaves_like 'ToNG', 401, false, false, false
      # it_behaves_like 'ToNG', 401, true, true, true
      it_behaves_like 'ToMsg', Array, 1, 'Unauthorized', nil, nil, nil
      # it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[APIログイン中][ない]有効なパラメータ' do
      let(:attributes) { valid_attributes }
      # it_behaves_like 'NG' # Tips: トークンが存在しない為、送信日時がない
      it_behaves_like 'ToOK'
      # it_behaves_like 'ToNG', 401, true, true, true
      it_behaves_like 'ToMsg', NilClass, 0, nil, 'devise_token_auth.passwords.successfully_updated', nil, nil
      # it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン/ログイン中][期限内]無効なパラメータ' do
      let(:attributes) { invalid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToNG', 422, false, false, false
      it_behaves_like 'ToMsg', Array, 1, 'devise_token_auth.passwords.missing_passwords', nil, nil, nil
      # it_behaves_like 'ToMsg', Hash, 2, 'activerecord.errors.models.user.attributes.password_confirmation.blank', 'errors.messages.not_saved.one', nil
    end
    shared_examples_for '[APIログイン中][期限内/期限切れ]無効なパラメータ' do
      let(:attributes) { invalid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToNG', 422, false, false, false
      # it_behaves_like 'ToNG', 401, true, true, true
      it_behaves_like 'ToMsg', Array, 1, 'devise_token_auth.passwords.missing_passwords', nil, nil, nil
      # it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン/ログイン中][期限切れ]無効なパラメータ' do
      let(:attributes) { invalid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToNG', 422, false, false, false
      it_behaves_like 'ToMsg', Array, 1, 'devise_token_auth.passwords.missing_passwords', nil, nil, nil
      # it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'activerecord.errors.models.user.attributes.reset_password_token.invalid', nil
    end
    shared_examples_for '[未ログイン/ログイン中][存在しない/ない/空]無効なパラメータ' do
      let(:attributes) { invalid_attributes }
      # it_behaves_like 'NG' # Tips: トークンが存在しない為、送信日時がない
      it_behaves_like 'ToNG', 401, false, false, false
      # it_behaves_like 'ToNG', 422, false, false, false
      it_behaves_like 'ToMsg', Array, 1, 'Unauthorized', nil, nil, nil
      # it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'activerecord.errors.models.user.attributes.reset_password_token.invalid', nil
    end
    shared_examples_for '[APIログイン中][存在しない/空]無効なパラメータ' do
      let(:attributes) { invalid_attributes }
      # it_behaves_like 'NG' # Tips: トークンが存在しない為、送信日時がない
      it_behaves_like 'ToNG', 401, false, false, false
      # it_behaves_like 'ToNG', 401, true, true, true
      it_behaves_like 'ToMsg', Array, 1, 'Unauthorized', nil, nil, nil
      # it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[APIログイン中][ない]無効なパラメータ' do
      let(:attributes) { invalid_attributes }
      # it_behaves_like 'NG' # Tips: トークンが存在しない為、送信日時がない
      it_behaves_like 'ToNG', 422, true, true, false
      # it_behaves_like 'ToNG', 401, true, true, true
      it_behaves_like 'ToMsg', Array, 1, 'devise_token_auth.passwords.missing_passwords', nil, nil, nil
      # it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise.failure.already_authenticated', nil
    end

    shared_examples_for '[未ログイン/ログイン中]トークンが期限内（未ロック）' do
      include_context 'パスワードリセットトークン作成', true
      it_behaves_like '[未ログイン/ログイン中][期限内/期限切れ]パラメータなし'
      it_behaves_like '[未ログイン/ログイン中][期限内]有効なパラメータ'
      it_behaves_like '[未ログイン/ログイン中][期限内]無効なパラメータ'
    end
    shared_examples_for '[APIログイン中]トークンが期限内（未ロック）' do
      include_context 'パスワードリセットトークン作成', true
      it_behaves_like '[APIログイン中][期限内/期限切れ]パラメータなし'
      it_behaves_like '[APIログイン中][期限内/期限切れ]有効なパラメータ'
      it_behaves_like '[APIログイン中][期限内/期限切れ]無効なパラメータ'
    end
    shared_examples_for '[未ログイン/ログイン中]トークンが期限内（ロック中）' do
      include_context 'パスワードリセットトークン作成', true, true
      it_behaves_like '[未ログイン/ログイン中][期限内/期限切れ]パラメータなし'
      it_behaves_like '[未ログイン/ログイン中][期限内]有効なパラメータ'
      it_behaves_like '[未ログイン/ログイン中][期限内]無効なパラメータ'
    end
    shared_examples_for '[APIログイン中]トークンが期限内（ロック中）' do
      include_context 'パスワードリセットトークン作成', true, true
      it_behaves_like '[APIログイン中][期限内/期限切れ]パラメータなし'
      it_behaves_like '[APIログイン中][期限内/期限切れ]有効なパラメータ'
      it_behaves_like '[APIログイン中][期限内/期限切れ]無効なパラメータ'
    end
    shared_examples_for '[未ログイン/ログイン中]トークンが期限内（メール未確認）' do
      include_context 'パスワードリセットトークン作成', true, false, true
      it_behaves_like '[未ログイン/ログイン中][期限内/期限切れ]パラメータなし'
      it_behaves_like '[未ログイン/ログイン中][期限内（メール未確認）]有効なパラメータ'
      it_behaves_like '[未ログイン/ログイン中][期限内]無効なパラメータ'
    end
    shared_examples_for '[APIログイン中]トークンが期限内（メール未確認）' do
      include_context 'パスワードリセットトークン作成', true, false, true
      it_behaves_like '[APIログイン中][期限内/期限切れ]パラメータなし'
      it_behaves_like '[APIログイン中][期限内/期限切れ]有効なパラメータ'
      it_behaves_like '[APIログイン中][期限内/期限切れ]無効なパラメータ'
    end
    shared_examples_for '[未ログイン/ログイン中]トークンが期限切れ' do
      include_context 'パスワードリセットトークン作成', false
      it_behaves_like '[未ログイン/ログイン中][期限内/期限切れ]パラメータなし'
      it_behaves_like '[未ログイン/ログイン中][期限切れ]有効なパラメータ'
      it_behaves_like '[未ログイン/ログイン中][期限切れ]無効なパラメータ'
    end
    shared_examples_for '[APIログイン中]トークンが期限切れ' do
      include_context 'パスワードリセットトークン作成', false
      it_behaves_like '[APIログイン中][期限内/期限切れ]パラメータなし'
      it_behaves_like '[APIログイン中][期限内/期限切れ]有効なパラメータ'
      it_behaves_like '[APIログイン中][期限内/期限切れ]無効なパラメータ'
    end
    shared_examples_for '[未ログイン/ログイン中]トークンが存在しない' do
      let(:reset_password_token) { NOT_TOKEN }
      it_behaves_like '[未ログイン/ログイン中][存在しない/ない/空]パラメータなし'
      it_behaves_like '[未ログイン/ログイン中][存在しない/ない/空]有効なパラメータ'
      it_behaves_like '[未ログイン/ログイン中][存在しない/ない/空]無効なパラメータ'
    end
    shared_examples_for '[APIログイン中]トークンが存在しない' do
      let(:reset_password_token) { NOT_TOKEN }
      it_behaves_like '[APIログイン中][存在しない/ない/空]パラメータなし'
      it_behaves_like '[APIログイン中][存在しない/空]有効なパラメータ'
      it_behaves_like '[APIログイン中][存在しない/空]無効なパラメータ'
    end
    shared_examples_for '[未ログイン/ログイン中]トークンがない' do
      let(:reset_password_token) { nil }
      it_behaves_like '[未ログイン/ログイン中][存在しない/ない/空]パラメータなし'
      it_behaves_like '[未ログイン/ログイン中][存在しない/ない/空]有効なパラメータ'
      it_behaves_like '[未ログイン/ログイン中][存在しない/ない/空]無効なパラメータ'
    end
    shared_examples_for '[APIログイン中]トークンがない' do
      let(:reset_password_token) { nil }
      it_behaves_like '[APIログイン中][存在しない/ない/空]パラメータなし'
      it_behaves_like '[APIログイン中][ない]有効なパラメータ'
      it_behaves_like '[APIログイン中][ない]無効なパラメータ'
    end
    shared_examples_for '[未ログイン/ログイン中]トークンが空' do
      let(:reset_password_token) { '' }
      it_behaves_like '[未ログイン/ログイン中][存在しない/ない/空]パラメータなし'
      it_behaves_like '[未ログイン/ログイン中][存在しない/ない/空]有効なパラメータ'
      it_behaves_like '[未ログイン/ログイン中][存在しない/ない/空]無効なパラメータ'
    end
    shared_examples_for '[APIログイン中]トークンが空' do
      let(:reset_password_token) { '' }
      it_behaves_like '[APIログイン中][存在しない/ない/空]パラメータなし'
      it_behaves_like '[APIログイン中][存在しない/空]有効なパラメータ'
      it_behaves_like '[APIログイン中][存在しない/空]無効なパラメータ'
    end

    shared_examples_for '未ログイン' do
      include_context '未ログイン処理'
      it_behaves_like '[未ログイン/ログイン中]トークンが期限内（未ロック）'
      it_behaves_like '[未ログイン/ログイン中]トークンが期限内（ロック中）'
      it_behaves_like '[未ログイン/ログイン中]トークンが期限内（メール未確認）'
      it_behaves_like '[未ログイン/ログイン中]トークンが期限切れ'
      it_behaves_like '[未ログイン/ログイン中]トークンが存在しない'
      it_behaves_like '[未ログイン/ログイン中]トークンがない'
      it_behaves_like '[未ログイン/ログイン中]トークンが空'
    end
    shared_examples_for 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[未ログイン/ログイン中]トークンが期限内（未ロック）'
      it_behaves_like '[未ログイン/ログイン中]トークンが期限内（ロック中）'
      it_behaves_like '[未ログイン/ログイン中]トークンが期限内（メール未確認）'
      it_behaves_like '[未ログイン/ログイン中]トークンが期限切れ'
      it_behaves_like '[未ログイン/ログイン中]トークンが存在しない'
      it_behaves_like '[未ログイン/ログイン中]トークンがない'
      it_behaves_like '[未ログイン/ログイン中]トークンが空'
    end
    shared_examples_for 'APIログイン中' do
      include_context 'APIログイン処理'
      it_behaves_like '[APIログイン中]トークンが期限内（未ロック）'
      it_behaves_like '[APIログイン中]トークンが期限内（ロック中）'
      it_behaves_like '[APIログイン中]トークンが期限内（メール未確認）'
      it_behaves_like '[APIログイン中]トークンが期限切れ'
      it_behaves_like '[APIログイン中]トークンが存在しない'
      it_behaves_like '[APIログイン中]トークンがない'
      it_behaves_like '[APIログイン中]トークンが空'
    end

    context 'URLの拡張子がない' do
      let(:subject_format) { nil }
      it_behaves_like '未ログイン'
      it_behaves_like 'ログイン中'
      it_behaves_like 'APIログイン中'
    end
    context 'URLの拡張子が.json' do
      let(:subject_format) { :json }
      it_behaves_like '未ログイン'
      it_behaves_like 'ログイン中'
      it_behaves_like 'APIログイン中'
    end
  end
end
