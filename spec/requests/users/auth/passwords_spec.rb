require 'rails_helper'

RSpec.describe 'Users::Auth::Passwords', type: :request do
  let(:response_json) { JSON.parse(response.body) }

  # テスト内容（共通）
  shared_examples_for 'ToMsg' do |error_class, errors_count, error_msg, message, alert, notice|
    let(:subject_format) { :json }
    let(:accept_headers) { ACCEPT_INC_JSON }
    it '対象のメッセージと一致する' do
      subject
      if error_msg.present?
        expect(response_json['errors'].to_s).to include(error_msg == 'Unauthorized' ? error_msg : get_locale(error_msg))
      else
        expect(response_json['errors'].to_s).to be_blank
      end
      expect(response_json['errors'].class).to eq(error_class) # 方針: バリデーション(Hash)のみ、他はalertへ
      expect(response_json['errors']&.count).to errors_count.positive? ? eq(errors_count) : be_nil
      expect(response_json['message']).to message.present? ? eq(get_locale(message)) : be_nil # 方針: 廃止して、noticeへ

      expect(response_json['alert']).to alert.present? ? eq(get_locale(alert)) : be_nil # 方針: 追加
      expect(response_json['notice']).to notice.present? ? eq(get_locale(notice)) : be_nil # 方針: 追加
    end
  end

  # POST /users/auth/password(.json) パスワード再設定API[メール送信](処理)
  # テストパターン
  #   未ログイン, ログイン中, APIログイン中
  #   パラメータなし, 有効なパラメータ（未ロック, ロック中, メール未確認）, 無効なパラメータ, URLがない, URLがホワイトリストにない
  #   ＋URLの拡張子: .json, ない
  #   ＋Acceptヘッダ: JSONが含まれる, JSONが含まれない
  describe 'POST #create' do
    subject { post create_user_auth_password_path(format: subject_format), params: attributes, headers: auth_headers.merge(accept_headers) }
    let_it_be(:send_user_unlocked)    { FactoryBot.create(:user) }
    let_it_be(:send_user_locked)      { FactoryBot.create(:user, :locked) }
    let_it_be(:send_user_unconfirmed) { FactoryBot.create(:user, :unconfirmed) }
    let_it_be(:not_user)              { FactoryBot.attributes_for(:user) }
    let(:valid_attributes)       { { email: send_user.email, redirect_url: FRONT_SITE_URL } }
    let(:invalid_attributes)     { { email: not_user[:email], redirect_url: FRONT_SITE_URL } }
    let(:invalid_nil_attributes) { { email: send_user_unlocked.email, redirect_url: nil } }
    let(:invalid_bad_attributes) { { email: send_user_unlocked.email, redirect_url: BAD_SITE_URL } }
    include_context 'Authテスト内容'
    let(:current_user) { nil }

    # テスト内容
    shared_examples_for 'OK' do
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      let(:url)       { "http://#{Settings.base_domain}#{edit_user_auth_password_path}" }
      let(:url_param) { "redirect_url=#{URI.encode_www_form_component(attributes[:redirect_url])}" }
      it 'メールが送信される' do
        subject
        expect(ActionMailer::Base.deliveries.count).to eq(1)
        expect(ActionMailer::Base.deliveries[0].subject).to eq(get_subject('devise.mailer.reset_password_instructions.subject')) # パスワード再設定方法のお知らせ
        expect(ActionMailer::Base.deliveries[0].html_part.body).to include(url)
        expect(ActionMailer::Base.deliveries[0].text_part.body).to include(url)
        expect(ActionMailer::Base.deliveries[0].html_part.body).to include(url_param)
        expect(ActionMailer::Base.deliveries[0].text_part.body).to include(url_param)
      end
    end
    shared_examples_for 'NG' do
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      it 'メールが送信されない' do
        expect { subject }.to change(ActionMailer::Base.deliveries, :count).by(0)
      end
    end

    shared_examples_for 'ToOK(json/json)' do
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      it 'HTTPステータスが200。対象項目が一致する。認証ヘッダがない' do
        is_expected.to eq(200)
        expect_success_json
        expect_not_exist_auth_header
      end
    end
    shared_examples_for 'ToNG(json/json)' do |code|
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      it "HTTPステータスが#{code}。対象項目が一致する。認証ヘッダがない" do
        is_expected.to eq(code) # 方針(優先順): 401: ログイン中, 400:パラメータなし, 422: 無効なパラメータ・状態
        expect_failure_json
        expect_not_exist_auth_header
      end
    end

    shared_examples_for 'ToOK' do
      it_behaves_like 'ToNG(html/html)', 406
      it_behaves_like 'ToNG(html/json)', 406
      it_behaves_like 'ToNG(json/html)', 406
      it_behaves_like 'ToOK(json/json)'
    end
    shared_examples_for 'ToNG' do |code|
      it_behaves_like 'ToNG(html/html)', 406
      it_behaves_like 'ToNG(html/json)', 406
      it_behaves_like 'ToNG(json/html)', 406
      it_behaves_like 'ToNG(json/json)', code
    end

    # テストケース
    shared_examples_for '[未ログイン/ログイン中]パラメータなし' do
      let(:attributes) { nil }
      it_behaves_like 'NG'
      # it_behaves_like 'ToNG', 422
      it_behaves_like 'ToNG', 400
      # it_behaves_like 'ToMsg', Array, 1, 'devise_token_auth.passwords.not_allowed_redirect_url', nil, nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'errors.messages.validate_password_params', nil
    end
    shared_examples_for '[APIログイン中]パラメータなし' do
      let(:attributes) { nil }
      it_behaves_like 'NG'
      # it_behaves_like 'ToNG', 422
      it_behaves_like 'ToNG', 401
      # it_behaves_like 'ToMsg', Array, 1, 'devise_token_auth.passwords.not_allowed_redirect_url', nil, nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン/ログイン中]有効なパラメータ（未ロック）' do
      let(:send_user)  { send_user_unlocked }
      let(:attributes) { valid_attributes }
      it_behaves_like 'OK'
      it_behaves_like 'ToOK'
      # it_behaves_like 'ToMsg', NilClass, 0, nil, 'devise_token_auth.passwords.sended', nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, nil, 'devise_token_auth.passwords.sended'
    end
    shared_examples_for '[APIログイン中]有効なパラメータ（未ロック）' do
      let(:send_user)  { send_user_unlocked }
      let(:attributes) { valid_attributes }
      # it_behaves_like 'OK'
      it_behaves_like 'NG'
      # it_behaves_like 'ToOK'
      it_behaves_like 'ToNG', 401
      # it_behaves_like 'ToMsg', NilClass, 0, nil, 'devise_token_auth.passwords.sended', nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン/ログイン中]有効なパラメータ（ロック中）' do # NOTE: ロック中も出来ても良さそう
      let(:send_user)  { send_user_locked }
      let(:attributes) { valid_attributes }
      it_behaves_like 'OK'
      it_behaves_like 'ToOK'
      # it_behaves_like 'ToMsg', NilClass, 0, nil, 'devise_token_auth.passwords.sended', nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, nil, 'devise_token_auth.passwords.sended'
    end
    shared_examples_for '[APIログイン中]有効なパラメータ（ロック中）' do
      let(:send_user)  { send_user_locked }
      let(:attributes) { valid_attributes }
      # it_behaves_like 'OK'
      it_behaves_like 'NG'
      # it_behaves_like 'ToOK'
      it_behaves_like 'ToNG', 401
      # it_behaves_like 'ToMsg', NilClass, 0, nil, 'devise_token_auth.passwords.sended', nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン/ログイン中]有効なパラメータ（メール未確認）' do # NOTE: メール未確認も出来ても良さそう
      let(:send_user)  { send_user_unconfirmed }
      let(:attributes) { valid_attributes }
      it_behaves_like 'OK'
      it_behaves_like 'ToOK'
      # it_behaves_like 'ToMsg', NilClass, 0, nil, 'devise_token_auth.passwords.sended', nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, nil, 'devise_token_auth.passwords.sended'
    end
    shared_examples_for '[APIログイン中]有効なパラメータ（メール未確認）' do
      let(:send_user)  { send_user_unconfirmed }
      let(:attributes) { valid_attributes }
      # it_behaves_like 'OK'
      it_behaves_like 'NG'
      # it_behaves_like 'ToOK'
      it_behaves_like 'ToNG', 401
      # it_behaves_like 'ToMsg', NilClass, 0, nil, 'devise_token_auth.passwords.sended', nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン/ログイン中]無効なパラメータ' do
      let(:attributes) { invalid_attributes }
      it_behaves_like 'NG'
      # it_behaves_like 'ToNG', 404
      it_behaves_like 'ToNG', 422
      # it_behaves_like 'ToMsg', Array, 1, 'devise_token_auth.passwords.user_not_found', nil, nil, nil
      it_behaves_like 'ToMsg', Hash, 2, 'devise_token_auth.passwords.user_not_found', nil, 'errors.messages.not_saved.one', nil
    end
    shared_examples_for '[APIログイン中]無効なパラメータ' do
      let(:attributes) { invalid_attributes }
      it_behaves_like 'NG'
      # it_behaves_like 'ToNG', 404
      it_behaves_like 'ToNG', 401
      # it_behaves_like 'ToMsg', Array, 1, 'devise_token_auth.passwords.user_not_found', nil, nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン/ログイン中]URLがない' do
      let(:attributes) { invalid_nil_attributes }
      it_behaves_like 'NG'
      # it_behaves_like 'ToNG', 401
      it_behaves_like 'ToNG', 422
      # it_behaves_like 'ToMsg', Array, 1, 'devise_token_auth.passwords.missing_redirect_url', nil, nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise_token_auth.passwords.missing_redirect_url', nil
    end
    shared_examples_for '[APIログイン中]URLがない' do
      let(:attributes) { invalid_nil_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToNG', 401
      # it_behaves_like 'ToMsg', Array, 1, 'devise_token_auth.passwords.missing_redirect_url', nil, nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン/ログイン中]URLがホワイトリストにない' do
      let(:attributes) { invalid_bad_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToNG', 422
      # it_behaves_like 'ToMsg', Array, 1, 'devise_token_auth.passwords.not_allowed_redirect_url', nil, nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise_token_auth.passwords.not_allowed_redirect_url', nil
    end
    shared_examples_for '[APIログイン中]URLがホワイトリストにない' do
      let(:attributes) { invalid_bad_attributes }
      it_behaves_like 'NG'
      # it_behaves_like 'ToNG', 422
      it_behaves_like 'ToNG', 401
      # it_behaves_like 'ToMsg', Array, 1, 'devise_token_auth.passwords.not_allowed_redirect_url', nil, nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise.failure.already_authenticated', nil
    end

    shared_examples_for '[未ログイン/ログイン中]' do
      it_behaves_like '[未ログイン/ログイン中]パラメータなし'
      it_behaves_like '[未ログイン/ログイン中]有効なパラメータ（未ロック）'
      it_behaves_like '[未ログイン/ログイン中]有効なパラメータ（ロック中）'
      it_behaves_like '[未ログイン/ログイン中]有効なパラメータ（メール未確認）'
      it_behaves_like '[未ログイン/ログイン中]無効なパラメータ'
      it_behaves_like '[未ログイン/ログイン中]URLがない'
      it_behaves_like '[未ログイン/ログイン中]URLがホワイトリストにない'
    end

    context '未ログイン' do
      include_context '未ログイン処理'
      it_behaves_like '[未ログイン/ログイン中]'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[未ログイン/ログイン中]'
    end
    context 'APIログイン中' do
      include_context 'APIログイン処理'
      it_behaves_like '[APIログイン中]パラメータなし'
      it_behaves_like '[APIログイン中]有効なパラメータ（未ロック）'
      it_behaves_like '[APIログイン中]有効なパラメータ（ロック中）'
      it_behaves_like '[APIログイン中]有効なパラメータ（メール未確認）'
      it_behaves_like '[APIログイン中]無効なパラメータ'
      it_behaves_like '[APIログイン中]URLがない'
      it_behaves_like '[APIログイン中]URLがホワイトリストにない'
    end
  end

  # GET /users/auth/password パスワード再設定
  # テストパターン
  #   未ログイン, ログイン中, APIログイン中
  #   トークン: 期限内（未ロック, ロック中, メール未確認）, 期限切れ, 存在しない, ない, 空
  #   ＋URLの拡張子: ない, .json
  #   ＋Acceptヘッダ: JSONが含まれない, JSONが含まれる
  #   ＋リダイレクトURL: ある, ない, ホワイトリストにない
  describe 'GET #edit' do
    subject do
      get edit_user_auth_password_path(format: subject_format, reset_password_token: reset_password_token, redirect_url: redirect_url),
          headers: auth_headers.merge(accept_headers)
    end

    # テスト内容
    shared_examples_for 'ToOK(html/*)' do
      it '指定URL（成功パラメータ）にリダイレクトする' do
        is_expected.to redirect_to("#{FRONT_SITE_URL}?reset_password_token=#{reset_password_token}")
      end
    end
    shared_examples_for 'ToNG(html/*)' do
      it '指定URL（失敗パラメータ）にリダイレクトする' do
        param = { reset_password: false }
        param[:alert] = get_locale(alert) if alert.present?
        param[:notice] = get_locale(notice) if notice.present?
        is_expected.to redirect_to("#{FRONT_SITE_URL}?#{URI.encode_www_form(param.sort)}")
      end
    end
    shared_examples_for 'ToNG(json/json)' do |code|
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      it "HTTPステータスが#{code}" do
        is_expected.to eq(code)
      end
    end

    shared_examples_for 'ToNG(html/html)' do
      let(:subject_format) { nil }
      let(:accept_headers) { ACCEPT_INC_HTML }
      it_behaves_like 'ToNG(html/*)'
    end
    shared_examples_for 'ToNG(html/json)' do
      let(:subject_format) { nil }
      let(:accept_headers) { ACCEPT_INC_JSON }
      it_behaves_like 'ToNG(html/*)'
    end

    shared_examples_for 'ToOK' do
      let(:redirect_url) { FRONT_SITE_URL }
      it_behaves_like 'ToOK(html/html)'
      it_behaves_like 'ToOK(html/json)'
      it_behaves_like 'ToNG(json/html)', 406
      it_behaves_like 'ToNG(json/json)', 406
    end
    shared_examples_for 'ToNG' do
      let(:redirect_url) { FRONT_SITE_URL }
      it_behaves_like 'ToNG(html/html)'
      it_behaves_like 'ToNG(html/json)'
      it_behaves_like 'ToNG(json/html)', 406
      it_behaves_like 'ToNG(json/json)', 406
    end

    shared_examples_for 'リダイレクトURLがない' do
      let(:subject_format) { nil }
      let(:accept_headers) { ACCEPT_INC_HTML }
      let(:redirect_url) { nil }
      # it 'HTTPステータスが422。対象項目が一致する' do
      it 'エラーページにリダイレクトする' do
        # is_expected.to eq(422)
        # expect(response_json['success']).to eq(false)
        # expect(response_json['errors']).not_to be_nil
        is_expected.to redirect_to(Settings.reset_password_error_url_not)
      end
    end
    shared_examples_for 'リダイレクトURLがホワイトリストにない' do
      let(:subject_format) { nil }
      let(:accept_headers) { ACCEPT_INC_HTML }
      let(:redirect_url) { BAD_SITE_URL }
      # it 'HTTPステータスが422。対象項目が一致する' do
      it 'エラーページにリダイレクトする' do
        # is_expected.to eq(422)
        # expect(response_json['success']).to eq(false)
        # expect(response_json['errors']).not_to be_nil
        is_expected.to redirect_to(Settings.reset_password_error_url_bad)
      end
    end

    # テストケース
    shared_examples_for '[*]トークンが期限内（未ロック）' do
      include_context 'パスワードリセットトークン作成', true
      it_behaves_like 'ToOK'
      it_behaves_like 'リダイレクトURLがない'
      it_behaves_like 'リダイレクトURLがホワイトリストにない'
    end
    shared_examples_for '[*]トークンが期限内（ロック中）' do # NOTE: ロック中も出来ても良さそう
      include_context 'パスワードリセットトークン作成', true, true
      it_behaves_like 'ToOK'
      it_behaves_like 'リダイレクトURLがない'
      it_behaves_like 'リダイレクトURLがホワイトリストにない'
    end
    shared_examples_for '[*]トークンが期限内（メール未確認）' do # NOTE: メール未確認も出来ても良さそう
      include_context 'パスワードリセットトークン作成', true, false, true
      it_behaves_like 'ToOK'
      it_behaves_like 'リダイレクトURLがない'
      it_behaves_like 'リダイレクトURLがホワイトリストにない'
    end
    shared_examples_for '[*]トークンが期限切れ' do
      # let(:alert)  { nil } # NOTE: ActionController::RoutingError: Not Found
      let(:alert)  { 'activerecord.errors.models.user.attributes.reset_password_token.invalid' }
      let(:notice) { nil }
      include_context 'パスワードリセットトークン作成', false
      it_behaves_like 'ToNG'
      it_behaves_like 'リダイレクトURLがない'
      it_behaves_like 'リダイレクトURLがホワイトリストにない'
    end
    shared_examples_for '[*]トークンが存在しない' do
      # let(:alert)  { nil } # NOTE: ActionController::RoutingError: Not Found
      let(:alert)  { 'activerecord.errors.models.user.attributes.reset_password_token.invalid' }
      let(:notice) { nil }
      let(:reset_password_token) { NOT_TOKEN }
      it_behaves_like 'ToNG'
      it_behaves_like 'リダイレクトURLがない'
      it_behaves_like 'リダイレクトURLがホワイトリストにない'
    end
    shared_examples_for '[*]トークンがない' do
      # let(:alert)  { nil } # NOTE: ActionController::RoutingError: Not Found
      let(:alert)  { 'activerecord.errors.models.user.attributes.reset_password_token.blank' }
      let(:notice) { nil }
      let(:reset_password_token) { nil }
      it_behaves_like 'ToNG'
      it_behaves_like 'リダイレクトURLがない'
      it_behaves_like 'リダイレクトURLがホワイトリストにない'
    end
    shared_examples_for '[*]トークンが空' do
      # let(:alert)  { nil } # NOTE: ActionController::RoutingError: Not Found
      let(:alert)  { 'activerecord.errors.models.user.attributes.reset_password_token.blank' }
      let(:notice) { nil }
      let(:reset_password_token) { '' }
      it_behaves_like 'ToNG'
      it_behaves_like 'リダイレクトURLがない'
      it_behaves_like 'リダイレクトURLがホワイトリストにない'
    end

    shared_examples_for '[*]' do
      it_behaves_like '[*]トークンが期限内（未ロック）'
      it_behaves_like '[*]トークンが期限内（ロック中）'
      it_behaves_like '[*]トークンが期限内（メール未確認）'
      it_behaves_like '[*]トークンが期限切れ'
      it_behaves_like '[*]トークンが存在しない'
      it_behaves_like '[*]トークンがない'
      it_behaves_like '[*]トークンが空'
    end

    context '未ログイン' do
      include_context '未ログイン処理'
      it_behaves_like '[*]'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[*]'
    end
    context 'APIログイン中' do
      include_context 'APIログイン処理'
      it_behaves_like '[*]'
    end
  end

  # POST /users/auth/password/update(.json) パスワード再設定API(処理)
  # テストパターン
  #   未ログイン, ログイン中, APIログイン中
  #   トークン: 期限内（未ロック, ロック中, メール未確認, メールアドレス変更中）, 期限切れ, 存在しない, ない, 空
  #   パラメータなし, 有効なパラメータ, 無効なパラメータ（なし, 確認なし）
  #   ＋URLの拡張子: .json, ない
  #   ＋Acceptヘッダ: JSONが含まれる, JSONが含まれない
  describe 'POST #update' do
    subject { post update_user_auth_password_path(format: subject_format), params: attributes, headers: auth_headers.merge(accept_headers) }
    let(:new_password) { Faker::Internet.password(min_length: 8) }
    let(:valid_attributes)           { { reset_password_token: reset_password_token, password: new_password, password_confirmation: new_password } }
    let(:invalid_attributes)         { { reset_password_token: reset_password_token, password: nil, password_confirmation: nil } }
    let(:invalid_confirm_attributes) { { reset_password_token: reset_password_token, password: new_password, password_confirmation: nil } }
    include_context 'Authテスト内容'
    let(:current_user) { User.find(send_user.id) }
    let(:inside_spaces) { [] } # TODO: send_userの参加スペースをセット

    # テスト内容
    shared_examples_for 'OK' do |change_confirmed = false|
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      let!(:start_time) { Time.current.floor }
      it "パスワードリセット送信日時がなし#{'・メールアドレス確認日時が現在日時' if change_confirmed}に変更される。メールが送信される" do
        subject
        expect(current_user.reset_password_sent_at).to be_nil
        expect(current_user.confirmed_at).to change_confirmed ? be_between(start_time, Time.current) : eq(send_user.confirmed_at)
        expect(current_user.locked_at).to be_nil # NOTE: ロック中の場合は解除する
        expect(current_user.failed_attempts).to eq(0)

        expect(ActionMailer::Base.deliveries.count).to eq(1)
        expect(ActionMailer::Base.deliveries[0].subject).to eq(get_subject('devise.mailer.password_change.subject')) # パスワード変更完了のお知らせ
      end
    end
    shared_examples_for 'NG' do
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      it 'パスワードリセット送信日時が変更されない。メールが送信されない' do
        subject
        expect(current_user.reset_password_sent_at).to eq(send_user.reset_password_sent_at)

        expect(ActionMailer::Base.deliveries.count).to eq(0)
      end
    end

    shared_examples_for 'ToOK(json/json)' do
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      it 'HTTPステータスが200。対象項目が一致する。認証ヘッダがある' do
        is_expected.to eq(200)
        expect_success_json
        expect_exist_auth_header
      end
    end
    shared_examples_for 'ToNG(json/json)' do |code| # , uid, client, token|
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      it "HTTPステータスが#{code}。対象項目が一致する。認証ヘッダがない" do
        is_expected.to eq(code) # 方針(優先順): 401: ログイン中, 400:パラメータなし, 422: 無効なパラメータ・状態
        expect_failure_json
        # expect(response.header['uid'].present?).to eq(uid)
        # expect(response.header['client'].present?).to eq(client)
        # expect(response.header['access-token'].present?).to eq(token)
        expect_not_exist_auth_header
      end
    end

    shared_examples_for 'ToOK' do
      it_behaves_like 'ToNG(html/html)', 406
      it_behaves_like 'ToNG(html/json)', 406
      it_behaves_like 'ToNG(json/html)', 406
      it_behaves_like 'ToOK(json/json)'
    end
    shared_examples_for 'ToNG' do |code| # , uid, client, token|
      it_behaves_like 'ToNG(html/html)', 406
      it_behaves_like 'ToNG(html/json)', 406
      it_behaves_like 'ToNG(json/html)', 406
      it_behaves_like 'ToNG(json/json)', code # , uid, client, token
    end

    # テストケース
    shared_examples_for '[未ログイン/ログイン中][期限内/期限切れ]パラメータなし' do
      let(:attributes) { nil }
      it_behaves_like 'NG'
      # it_behaves_like 'ToNG', 401, false, false, false
      it_behaves_like 'ToNG', 400, false, false, false
      # it_behaves_like 'ToMsg', Array, 1, 'Unauthorized', nil, nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'errors.messages.validate_password_params', nil
    end
    shared_examples_for '[APIログイン中][期限内/期限切れ]パラメータなし' do
      let(:attributes) { nil }
      it_behaves_like 'NG'
      # it_behaves_like 'ToNG', 422, true, true, false
      it_behaves_like 'ToNG', 401, false, false, false
      # it_behaves_like 'ToMsg', Array, 1, 'devise_token_auth.passwords.missing_passwords', nil, nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン/ログイン中][存在しない/ない/空]パラメータなし' do
      let(:attributes) { nil }
      # it_behaves_like 'NG' # NOTE: トークンが存在しない為、送信日時がない
      # it_behaves_like 'ToNG', 401, false, false, false
      it_behaves_like 'ToNG', 400, false, false, false
      # it_behaves_like 'ToMsg', Array, 1, 'Unauthorized', nil, nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'errors.messages.validate_password_params', nil
    end
    shared_examples_for '[APIログイン中][存在しない/ない/空]パラメータなし' do
      let(:attributes) { nil }
      # it_behaves_like 'NG' # NOTE: トークンが存在しない為、送信日時がない
      # it_behaves_like 'ToNG', 422, true, true, false
      it_behaves_like 'ToNG', 401, false, false, false
      # it_behaves_like 'ToMsg', Array, 1, 'devise_token_auth.passwords.missing_passwords', nil, nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン/ログイン中][期限内]有効なパラメータ' do
      let(:attributes) { valid_attributes }
      it_behaves_like 'OK'
      it_behaves_like 'ToOK'
      # it_behaves_like 'ToMsg', NilClass, 0, nil, 'devise_token_auth.passwords.successfully_updated', nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, nil, 'devise_token_auth.passwords.successfully_updated'
    end
    shared_examples_for '[未ログイン/ログイン中][期限内（メール未確認）]有効なパラメータ' do
      let(:attributes) { valid_attributes }
      # it_behaves_like 'OK'
      it_behaves_like 'OK', true
      it_behaves_like 'ToOK'
      # it_behaves_like 'ToMsg', NilClass, 0, nil, 'devise_token_auth.passwords.successfully_updated', nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, nil, 'devise_token_auth.passwords.successfully_updated'
    end
    shared_examples_for '[未ログイン/ログイン中][期限内（メールアドレス変更中）]有効なパラメータ' do
      let(:attributes) { valid_attributes }
      it_behaves_like 'OK'
      it_behaves_like 'ToOK'
      # it_behaves_like 'ToMsg', NilClass, 0, nil, 'devise_token_auth.passwords.successfully_updated', nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise.failure.unconfirmed', 'devise_token_auth.passwords.successfully_updated'
    end
    shared_examples_for '[APIログイン中][期限内/期限切れ]有効なパラメータ' do
      let(:attributes) { valid_attributes }
      # it_behaves_like 'OK'
      it_behaves_like 'NG'
      # it_behaves_like 'ToOK'
      it_behaves_like 'ToNG', 401, false, false, false
      # it_behaves_like 'ToMsg', NilClass, 0, nil, 'devise_token_auth.passwords.successfully_updated', nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン/ログイン中][期限切れ]有効なパラメータ' do
      let(:attributes) { valid_attributes }
      # it_behaves_like 'OK'
      it_behaves_like 'NG'
      # it_behaves_like 'ToOK'
      it_behaves_like 'ToNG', 422, false, false, false
      # it_behaves_like 'ToMsg', NilClass, 0, nil, 'devise_token_auth.passwords.successfully_updated', nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'activerecord.errors.models.user.attributes.reset_password_token.invalid', nil
    end
    shared_examples_for '[未ログイン/ログイン中][存在しない/ない/空]有効なパラメータ' do
      let(:attributes) { valid_attributes }
      # it_behaves_like 'NG' # NOTE: トークンが存在しない為、送信日時がない
      # it_behaves_like 'ToNG', 401, false, false, false
      it_behaves_like 'ToNG', 422, false, false, false
      # it_behaves_like 'ToMsg', Array, 1, 'Unauthorized', nil, nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'activerecord.errors.models.user.attributes.reset_password_token.invalid', nil
    end
    shared_examples_for '[APIログイン中][存在しない/空]有効なパラメータ' do
      let(:attributes) { valid_attributes }
      # it_behaves_like 'NG' # NOTE: トークンが存在しない為、送信日時がない
      # it_behaves_like 'ToNG', 401, false, false, false
      it_behaves_like 'ToNG', 401, false, false, false
      # it_behaves_like 'ToMsg', Array, 1, 'Unauthorized', nil, nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[APIログイン中][ない]有効なパラメータ' do
      let(:attributes) { valid_attributes }
      # it_behaves_like 'NG' # NOTE: トークンが存在しない為、送信日時がない
      # it_behaves_like 'ToOK'
      it_behaves_like 'ToNG', 401, false, false, false
      # it_behaves_like 'ToMsg', NilClass, 0, nil, 'devise_token_auth.passwords.successfully_updated', nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン/ログイン中][期限内]無効なパラメータ（なし）' do
      let(:attributes) { invalid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToNG', 422, false, false, false
      # it_behaves_like 'ToMsg', Array, 1, 'devise_token_auth.passwords.missing_passwords', nil, nil, nil
      error_msg = 'activerecord.errors.models.user.attributes.password.blank'
      it_behaves_like 'ToMsg', Hash, 2, error_msg, nil, 'errors.messages.not_saved.one', nil
    end
    shared_examples_for '[APIログイン中][期限内/期限切れ]無効なパラメータ（なし）' do
      let(:attributes) { invalid_attributes }
      it_behaves_like 'NG'
      # it_behaves_like 'ToNG', 422, false, false, false
      it_behaves_like 'ToNG', 401, false, false, false
      # it_behaves_like 'ToMsg', Array, 1, 'devise_token_auth.passwords.missing_passwords', nil, nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン/ログイン中][期限切れ]無効なパラメータ（なし）' do
      let(:attributes) { invalid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToNG', 422, false, false, false
      # it_behaves_like 'ToMsg', Array, 1, 'devise_token_auth.passwords.missing_passwords', nil, nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'activerecord.errors.models.user.attributes.reset_password_token.invalid', nil
    end
    shared_examples_for '[未ログイン/ログイン中][存在しない/ない/空]無効なパラメータ（なし）' do
      let(:attributes) { invalid_attributes }
      # it_behaves_like 'NG' # NOTE: トークンが存在しない為、送信日時がない
      # it_behaves_like 'ToNG', 401, false, false, false
      it_behaves_like 'ToNG', 422, false, false, false
      # it_behaves_like 'ToMsg', Array, 1, 'Unauthorized', nil, nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'activerecord.errors.models.user.attributes.reset_password_token.invalid', nil
    end
    shared_examples_for '[APIログイン中][存在しない/空]無効なパラメータ（なし）' do
      let(:attributes) { invalid_attributes }
      # it_behaves_like 'NG' # NOTE: トークンが存在しない為、送信日時がない
      # it_behaves_like 'ToNG', 401, false, false, false
      it_behaves_like 'ToNG', 401, false, false, false
      # it_behaves_like 'ToMsg', Array, 1, 'Unauthorized', nil, nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[APIログイン中][ない]無効なパラメータ（なし）' do
      let(:attributes) { invalid_attributes }
      # it_behaves_like 'NG' # NOTE: トークンが存在しない為、送信日時がない
      # it_behaves_like 'ToNG', 422, true, true, false
      it_behaves_like 'ToNG', 401, false, false, false
      # it_behaves_like 'ToMsg', Array, 1, 'devise_token_auth.passwords.missing_passwords', nil, nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン/ログイン中][期限内]無効なパラメータ（確認なし）' do
      let(:attributes) { invalid_confirm_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToNG', 422, false, false, false
      # it_behaves_like 'ToMsg', Array, 1, 'devise_token_auth.passwords.missing_passwords', nil, nil, nil
      error_msg = 'activerecord.errors.models.user.attributes.password_confirmation.confirmation'
      it_behaves_like 'ToMsg', Hash, 2, error_msg, nil, 'errors.messages.not_saved.one', nil
    end
    shared_examples_for '[APIログイン中][期限内/期限切れ]無効なパラメータ（確認なし）' do
      let(:attributes) { invalid_confirm_attributes }
      it_behaves_like 'NG'
      # it_behaves_like 'ToNG', 422, false, false, false
      it_behaves_like 'ToNG', 401, false, false, false
      # it_behaves_like 'ToMsg', Array, 1, 'devise_token_auth.passwords.missing_passwords', nil, nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン/ログイン中][期限切れ]無効なパラメータ（確認なし）' do
      let(:attributes) { invalid_confirm_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToNG', 422, false, false, false
      # it_behaves_like 'ToMsg', Array, 1, 'devise_token_auth.passwords.missing_passwords', nil, nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'activerecord.errors.models.user.attributes.reset_password_token.invalid', nil
    end
    shared_examples_for '[未ログイン/ログイン中][存在しない/ない/空]無効なパラメータ（確認なし）' do
      let(:attributes) { invalid_confirm_attributes }
      # it_behaves_like 'NG' # NOTE: トークンが存在しない為、送信日時がない
      # it_behaves_like 'ToNG', 401, false, false, false
      it_behaves_like 'ToNG', 422, false, false, false
      # it_behaves_like 'ToMsg', Array, 1, 'Unauthorized', nil, nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'activerecord.errors.models.user.attributes.reset_password_token.invalid', nil
    end
    shared_examples_for '[APIログイン中][存在しない/空]無効なパラメータ（確認なし）' do
      let(:attributes) { invalid_confirm_attributes }
      # it_behaves_like 'NG' # NOTE: トークンが存在しない為、送信日時がない
      # it_behaves_like 'ToNG', 401, false, false, false
      it_behaves_like 'ToNG', 401, false, false, false
      # it_behaves_like 'ToMsg', Array, 1, 'Unauthorized', nil, nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[APIログイン中][ない]無効なパラメータ（確認なし）' do
      let(:attributes) { invalid_confirm_attributes }
      # it_behaves_like 'NG' # NOTE: トークンが存在しない為、送信日時がない
      # it_behaves_like 'ToNG', 422, true, true, false
      it_behaves_like 'ToNG', 401, false, false, false
      # it_behaves_like 'ToMsg', Array, 1, 'devise_token_auth.passwords.missing_passwords', nil, nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise.failure.already_authenticated', nil
    end

    shared_examples_for '[未ログイン/ログイン中]トークンが期限内（未ロック）' do
      include_context 'パスワードリセットトークン作成', true
      it_behaves_like '[未ログイン/ログイン中][期限内/期限切れ]パラメータなし'
      it_behaves_like '[未ログイン/ログイン中][期限内]有効なパラメータ'
      it_behaves_like '[未ログイン/ログイン中][期限内]無効なパラメータ（なし）'
      it_behaves_like '[未ログイン/ログイン中][期限内]無効なパラメータ（確認なし）'
    end
    shared_examples_for '[APIログイン中]トークンが期限内（未ロック）' do
      include_context 'パスワードリセットトークン作成', true
      it_behaves_like '[APIログイン中][期限内/期限切れ]パラメータなし'
      it_behaves_like '[APIログイン中][期限内/期限切れ]有効なパラメータ'
      it_behaves_like '[APIログイン中][期限内/期限切れ]無効なパラメータ（なし）'
      it_behaves_like '[APIログイン中][期限内/期限切れ]無効なパラメータ（確認なし）'
    end
    shared_examples_for '[未ログイン/ログイン中]トークンが期限内（ロック中）' do
      include_context 'パスワードリセットトークン作成', true, true
      it_behaves_like '[未ログイン/ログイン中][期限内/期限切れ]パラメータなし'
      it_behaves_like '[未ログイン/ログイン中][期限内]有効なパラメータ'
      it_behaves_like '[未ログイン/ログイン中][期限内]無効なパラメータ（なし）'
      it_behaves_like '[未ログイン/ログイン中][期限内]無効なパラメータ（確認なし）'
    end
    shared_examples_for '[APIログイン中]トークンが期限内（ロック中）' do
      include_context 'パスワードリセットトークン作成', true, true
      it_behaves_like '[APIログイン中][期限内/期限切れ]パラメータなし'
      it_behaves_like '[APIログイン中][期限内/期限切れ]有効なパラメータ'
      it_behaves_like '[APIログイン中][期限内/期限切れ]無効なパラメータ（なし）'
      it_behaves_like '[APIログイン中][期限内/期限切れ]無効なパラメータ（確認なし）'
    end
    shared_examples_for '[未ログイン/ログイン中]トークンが期限内（メール未確認）' do
      include_context 'パスワードリセットトークン作成', true, false, true
      it_behaves_like '[未ログイン/ログイン中][期限内/期限切れ]パラメータなし'
      it_behaves_like '[未ログイン/ログイン中][期限内（メール未確認）]有効なパラメータ'
      it_behaves_like '[未ログイン/ログイン中][期限内]無効なパラメータ（なし）'
      it_behaves_like '[未ログイン/ログイン中][期限内]無効なパラメータ（確認なし）'
    end
    shared_examples_for '[APIログイン中]トークンが期限内（メール未確認）' do
      include_context 'パスワードリセットトークン作成', true, false, true
      it_behaves_like '[APIログイン中][期限内/期限切れ]パラメータなし'
      it_behaves_like '[APIログイン中][期限内/期限切れ]有効なパラメータ'
      it_behaves_like '[APIログイン中][期限内/期限切れ]無効なパラメータ（なし）'
      it_behaves_like '[APIログイン中][期限内/期限切れ]無効なパラメータ（確認なし）'
    end
    shared_examples_for '[未ログイン/ログイン中]トークンが期限内（メールアドレス変更中）' do
      include_context 'パスワードリセットトークン作成', true, false, true, true
      it_behaves_like '[未ログイン/ログイン中][期限内/期限切れ]パラメータなし'
      it_behaves_like '[未ログイン/ログイン中][期限内（メールアドレス変更中）]有効なパラメータ'
      it_behaves_like '[未ログイン/ログイン中][期限内]無効なパラメータ（なし）'
      it_behaves_like '[未ログイン/ログイン中][期限内]無効なパラメータ（確認なし）'
    end
    shared_examples_for '[APIログイン中]トークンが期限内（メールアドレス変更中）' do
      include_context 'パスワードリセットトークン作成', true, false, true, true
      it_behaves_like '[APIログイン中][期限内/期限切れ]パラメータなし'
      it_behaves_like '[APIログイン中][期限内/期限切れ]有効なパラメータ'
      it_behaves_like '[APIログイン中][期限内/期限切れ]無効なパラメータ（なし）'
      it_behaves_like '[APIログイン中][期限内/期限切れ]無効なパラメータ（確認なし）'
    end
    shared_examples_for '[未ログイン/ログイン中]トークンが期限切れ' do
      include_context 'パスワードリセットトークン作成', false
      it_behaves_like '[未ログイン/ログイン中][期限内/期限切れ]パラメータなし'
      it_behaves_like '[未ログイン/ログイン中][期限切れ]有効なパラメータ'
      it_behaves_like '[未ログイン/ログイン中][期限切れ]無効なパラメータ（なし）'
      it_behaves_like '[未ログイン/ログイン中][期限切れ]無効なパラメータ（確認なし）'
    end
    shared_examples_for '[APIログイン中]トークンが期限切れ' do
      include_context 'パスワードリセットトークン作成', false
      it_behaves_like '[APIログイン中][期限内/期限切れ]パラメータなし'
      it_behaves_like '[APIログイン中][期限内/期限切れ]有効なパラメータ'
      it_behaves_like '[APIログイン中][期限内/期限切れ]無効なパラメータ（なし）'
      it_behaves_like '[APIログイン中][期限内/期限切れ]無効なパラメータ（確認なし）'
    end
    shared_examples_for '[未ログイン/ログイン中]トークンが存在しない' do
      let(:reset_password_token) { NOT_TOKEN }
      it_behaves_like '[未ログイン/ログイン中][存在しない/ない/空]パラメータなし'
      it_behaves_like '[未ログイン/ログイン中][存在しない/ない/空]有効なパラメータ'
      it_behaves_like '[未ログイン/ログイン中][存在しない/ない/空]無効なパラメータ（なし）'
      it_behaves_like '[未ログイン/ログイン中][存在しない/ない/空]無効なパラメータ（確認なし）'
    end
    shared_examples_for '[APIログイン中]トークンが存在しない' do
      let(:reset_password_token) { NOT_TOKEN }
      it_behaves_like '[APIログイン中][存在しない/ない/空]パラメータなし'
      it_behaves_like '[APIログイン中][存在しない/空]有効なパラメータ'
      it_behaves_like '[APIログイン中][存在しない/空]無効なパラメータ（なし）'
      it_behaves_like '[APIログイン中][存在しない/空]無効なパラメータ（確認なし）'
    end
    shared_examples_for '[未ログイン/ログイン中]トークンがない' do
      let(:reset_password_token) { nil }
      it_behaves_like '[未ログイン/ログイン中][存在しない/ない/空]パラメータなし'
      it_behaves_like '[未ログイン/ログイン中][存在しない/ない/空]有効なパラメータ'
      it_behaves_like '[未ログイン/ログイン中][存在しない/ない/空]無効なパラメータ（なし）'
      it_behaves_like '[未ログイン/ログイン中][存在しない/ない/空]無効なパラメータ（確認なし）'
    end
    shared_examples_for '[APIログイン中]トークンがない' do
      let(:reset_password_token) { nil }
      it_behaves_like '[APIログイン中][存在しない/ない/空]パラメータなし'
      it_behaves_like '[APIログイン中][ない]有効なパラメータ'
      it_behaves_like '[APIログイン中][ない]無効なパラメータ（なし）'
      it_behaves_like '[APIログイン中][ない]無効なパラメータ（確認なし）'
    end
    shared_examples_for '[未ログイン/ログイン中]トークンが空' do
      let(:reset_password_token) { '' }
      it_behaves_like '[未ログイン/ログイン中][存在しない/ない/空]パラメータなし'
      it_behaves_like '[未ログイン/ログイン中][存在しない/ない/空]有効なパラメータ'
      it_behaves_like '[未ログイン/ログイン中][存在しない/ない/空]無効なパラメータ（なし）'
      it_behaves_like '[未ログイン/ログイン中][存在しない/ない/空]無効なパラメータ（確認なし）'
    end
    shared_examples_for '[APIログイン中]トークンが空' do
      let(:reset_password_token) { '' }
      it_behaves_like '[APIログイン中][存在しない/ない/空]パラメータなし'
      it_behaves_like '[APIログイン中][存在しない/空]有効なパラメータ'
      it_behaves_like '[APIログイン中][存在しない/空]無効なパラメータ（なし）'
      it_behaves_like '[APIログイン中][存在しない/空]無効なパラメータ（確認なし）'
    end

    shared_examples_for '[未ログイン/ログイン中]' do
      it_behaves_like '[未ログイン/ログイン中]トークンが期限内（未ロック）'
      it_behaves_like '[未ログイン/ログイン中]トークンが期限内（ロック中）'
      it_behaves_like '[未ログイン/ログイン中]トークンが期限内（メール未確認）'
      it_behaves_like '[未ログイン/ログイン中]トークンが期限内（メールアドレス変更中）'
      it_behaves_like '[未ログイン/ログイン中]トークンが期限切れ'
      it_behaves_like '[未ログイン/ログイン中]トークンが存在しない'
      it_behaves_like '[未ログイン/ログイン中]トークンがない'
      it_behaves_like '[未ログイン/ログイン中]トークンが空'
    end

    context '未ログイン' do
      include_context '未ログイン処理'
      it_behaves_like '[未ログイン/ログイン中]'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[未ログイン/ログイン中]'
    end
    context 'APIログイン中' do
      include_context 'APIログイン処理'
      it_behaves_like '[APIログイン中]トークンが期限内（未ロック）'
      it_behaves_like '[APIログイン中]トークンが期限内（ロック中）'
      it_behaves_like '[APIログイン中]トークンが期限内（メール未確認）'
      it_behaves_like '[APIログイン中]トークンが期限内（メールアドレス変更中）'
      it_behaves_like '[APIログイン中]トークンが期限切れ'
      it_behaves_like '[APIログイン中]トークンが存在しない'
      it_behaves_like '[APIログイン中]トークンがない'
      it_behaves_like '[APIログイン中]トークンが空'
    end
  end
end
