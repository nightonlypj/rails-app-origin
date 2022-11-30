require 'rails_helper'

RSpec.describe 'Users::Auth::Confirmations', type: :request do
  let(:response_json) { JSON.parse(response.body) }

  # テスト内容（共通）
  shared_examples_for 'ToMsg' do |error_class, errors_count, error_msg, message, alert, notice|
    let(:subject_format) { :json }
    let(:accept_headers) { ACCEPT_INC_JSON }
    it '対象のメッセージと一致する' do
      subject
      expect(response_json['errors'].to_s).to error_msg.present? ? include(I18n.t(error_msg)) : be_blank
      expect(response_json['errors'].class).to eq(error_class) # 方針: バリデーション(Hash)のみ、他はalertへ
      expect(response_json['errors']&.count).to errors_count.positive? ? eq(errors_count) : be_nil
      expect(response_json['message']).to message.present? ? eq(I18n.t(message)) : be_nil # 方針: 廃止して、noticeへ

      expect(response_json['alert']).to alert.present? ? eq(I18n.t(alert)) : be_nil # 方針: 追加
      expect(response_json['notice']).to notice.present? ? eq(I18n.t(notice)) : be_nil # 方針: 追加
    end
  end

  # POST /users/auth/confirmation(.json) メールアドレス確認API[メール再送](処理)
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, APIログイン中
  #   パラメータなし, 有効なパラメータ（メール未確認, メール確認済み, メールアドレス変更中）, 無効なパラメータ, URLがない, URLがホワイトリストにない
  #   ＋URLの拡張子: .json, ない
  #   ＋Acceptヘッダ: JSONが含まれる, JSONが含まれない
  describe 'POST #create' do
    subject { post create_user_auth_confirmation_path(format: subject_format), params: attributes, headers: auth_headers.merge(accept_headers) }
    let_it_be(:send_user_unconfirmed)   { FactoryBot.create(:user, :unconfirmed) }
    let_it_be(:send_user_confirmed)     { FactoryBot.create(:user) }
    let_it_be(:send_user_email_changed) { FactoryBot.create(:user, :email_changed) }
    let_it_be(:not_user)                { FactoryBot.attributes_for(:user) }
    let(:valid_attributes)       { { email: send_user.email, redirect_url: FRONT_SITE_URL } }
    let(:invalid_attributes)     { { email: not_user[:email], redirect_url: FRONT_SITE_URL } }
    let(:invalid_nil_attributes) { { email: send_user_unconfirmed.email, redirect_url: nil } }
    let(:invalid_bad_attributes) { { email: send_user_unconfirmed.email, redirect_url: BAD_SITE_URL } }
    include_context 'Authテスト内容'
    let(:current_user) { nil }

    # テスト内容
    shared_examples_for 'OK' do
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      let(:url)       { "http://#{Settings['base_domain']}#{user_auth_confirmation_path}" }
      let(:url_param) { "redirect_url=#{URI.encode_www_form_component(attributes[:redirect_url])}" }
      it 'メールが送信される' do
        subject
        expect(ActionMailer::Base.deliveries.count).to eq(1)
        expect(ActionMailer::Base.deliveries[0].subject).to eq(get_subject('devise.mailer.confirmation_instructions.subject')) # メールアドレス確認のお願い
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
        is_expected.to eq(code) # 方針(優先順): 400:パラメータなし, 422: 無効なパラメータ・状態
        expect_failure_json
        expect_not_exist_auth_header
      end
    end

    shared_examples_for 'ToOK' do
      it_behaves_like 'ToOK(json/json)'
      it_behaves_like 'To406(json/html)'
      it_behaves_like 'To406(html/json)'
      it_behaves_like 'To406(html/html)'
    end
    shared_examples_for 'ToNG' do |code|
      it_behaves_like 'ToNG(json/json)', code
      it_behaves_like 'To406(json/html)'
      it_behaves_like 'To406(html/json)'
      it_behaves_like 'To406(html/html)'
    end

    # テストケース
    shared_examples_for '[*]パラメータなし' do
      let(:attributes) { nil }
      it_behaves_like 'NG'
      # it_behaves_like 'ToNG', 401
      it_behaves_like 'ToNG', 400
      # it_behaves_like 'ToMsg', Array, 1, 'devise_token_auth.confirmations.missing_email', nil, nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'errors.messages.validate_confirmation_params', nil
    end
    shared_examples_for '[*]有効なパラメータ（メール未確認）' do # NOTE: ログイン中も出来ても良さそう
      let(:send_user)  { send_user_unconfirmed }
      let(:attributes) { valid_attributes }
      it_behaves_like 'OK'
      it_behaves_like 'ToOK'
      # it_behaves_like 'ToMsg', NilClass, 0, nil, 'devise_token_auth.confirmations.sended', nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, nil, 'devise_token_auth.confirmations.sended'
    end
    shared_examples_for '[*]有効なパラメータ（メール確認済み）' do
      let(:send_user)  { send_user_confirmed }
      let(:attributes) { valid_attributes }
      # it_behaves_like 'OK'
      it_behaves_like 'NG'
      # it_behaves_like 'ToOK'
      it_behaves_like 'ToNG', 422
      # it_behaves_like 'ToMsg', NilClass, 0, nil, 'devise_token_auth.confirmations.sended', nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'errors.messages.already_confirmed', nil
    end
    shared_examples_for '[*]有効なパラメータ（メールアドレス変更中）' do # NOTE: ログイン中でも再送したい
      let(:send_user)  { send_user_email_changed }
      let(:attributes) { valid_attributes }
      it_behaves_like 'OK'
      it_behaves_like 'ToOK'
      # it_behaves_like 'ToMsg', NilClass, 0, nil, 'devise_token_auth.confirmations.sended', nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, nil, 'devise_token_auth.confirmations.sended'
    end
    shared_examples_for '[*]無効なパラメータ' do
      let(:attributes) { invalid_attributes }
      it_behaves_like 'NG'
      # it_behaves_like 'ToNG', 404
      it_behaves_like 'ToNG', 422
      # it_behaves_like 'ToMsg', Array, 1, 'devise_token_auth.confirmations.user_not_found', nil, nil, nil
      it_behaves_like 'ToMsg', Hash, 2, 'devise_token_auth.confirmations.user_not_found', nil, 'errors.messages.not_saved.one', nil
    end
    shared_examples_for '[*]URLがない' do
      let(:attributes) { invalid_nil_attributes }
      # it_behaves_like 'OK'
      it_behaves_like 'NG'
      # it_behaves_like 'ToOK'
      it_behaves_like 'ToNG', 422
      # it_behaves_like 'ToMsg', NilClass, 0, nil, 'devise_token_auth.confirmations.sended', nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise_token_auth.confirmations.missing_confirm_success_url', nil
    end
    shared_examples_for '[*]URLがホワイトリストにない' do
      let(:attributes) { invalid_bad_attributes }
      # it_behaves_like 'OK'
      it_behaves_like 'NG'
      # it_behaves_like 'ToOK'
      it_behaves_like 'ToNG', 422
      # it_behaves_like 'ToMsg', NilClass, 0, nil, 'devise_token_auth.confirmations.sended', nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise_token_auth.confirmations.redirect_url_not_allowed', nil
    end

    context '未ログイン' do
      include_context '未ログイン処理'
      it_behaves_like '[*]パラメータなし'
      it_behaves_like '[*]有効なパラメータ（メール未確認）'
      it_behaves_like '[*]有効なパラメータ（メール確認済み）'
      it_behaves_like '[*]有効なパラメータ（メールアドレス変更中）'
      it_behaves_like '[*]無効なパラメータ'
      it_behaves_like '[*]URLがない'
      it_behaves_like '[*]URLがホワイトリストにない'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[*]パラメータなし'
      it_behaves_like '[*]有効なパラメータ（メール未確認）'
      it_behaves_like '[*]有効なパラメータ（メール確認済み）'
      it_behaves_like '[*]有効なパラメータ（メールアドレス変更中）'
      it_behaves_like '[*]無効なパラメータ'
      it_behaves_like '[*]URLがない'
      it_behaves_like '[*]URLがホワイトリストにない'
    end
    context 'APIログイン中' do
      include_context 'APIログイン処理'
      it_behaves_like '[*]パラメータなし'
      it_behaves_like '[*]有効なパラメータ（メール未確認）'
      it_behaves_like '[*]有効なパラメータ（メール確認済み）'
      it_behaves_like '[*]有効なパラメータ（メールアドレス変更中）'
      it_behaves_like '[*]無効なパラメータ'
      it_behaves_like '[*]URLがない'
      it_behaves_like '[*]URLがホワイトリストにない'
    end
  end

  # GET /users/auth/confirmation メールアドレス確認(処理)
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, APIログイン中
  #   トークン: 期限内, 期限切れ, 存在しない, ない, 空
  #   確認日時: ない（未確認）, 確認送信日時より前（未確認）, 確認送信日時より後（確認済み）
  #   ＋URLの拡張子: ない, .json
  #   ＋Acceptヘッダ: JSONが含まれない, JSONが含まれる
  #   ＋リダイレクトURL: ある, ない, ホワイトリストにない
  describe 'GET #show' do
    subject do
      get user_auth_confirmation_path(format: subject_format, confirmation_token: confirmation_token, redirect_url: @redirect_url),
          headers: auth_headers.merge(accept_headers)
    end
    let(:current_user) { User.find(send_user.id) }

    # テスト内容
    shared_examples_for 'OK' do
      let(:subject_format) { nil }
      let(:accept_headers) { ACCEPT_INC_HTML }
      let!(:start_time) { Time.now.utc.floor }
      it '[リダイレクトURLがある]確認日時が現在日時に変更される' do
        @redirect_url = FRONT_SITE_URL
        subject
        expect(current_user.confirmed_at).to be_between(start_time, Time.now.utc)
      end
      it '[リダイレクトURLがない]確認日時が現在日時に変更される' do
        @redirect_url = nil
        subject
        expect(current_user.confirmed_at).to be_between(start_time, Time.now.utc)
      end
      it '[リダイレクトURLがホワイトリストにない]確認日時が現在日時に変更される' do
        @redirect_url = BAD_SITE_URL
        subject
        expect(current_user.confirmed_at).to be_between(start_time, Time.now.utc)
      end
    end
    shared_examples_for 'NG' do
      let(:subject_format) { nil }
      let(:accept_headers) { ACCEPT_INC_HTML }
      it '[リダイレクトURLがある]確認日時が変更されない' do
        @redirect_url = FRONT_SITE_URL
        subject
        expect(current_user.confirmed_at).to eq(send_user.confirmed_at)
      end
      it '[リダイレクトURLがない]確認日時が変更されない' do
        @redirect_url = nil
        subject
        expect(current_user.confirmed_at).to eq(send_user.confirmed_at)
      end
      it '[リダイレクトURLがホワイトリストにない]確認日時が変更されない' do
        @redirect_url = BAD_SITE_URL
        subject
        expect(current_user.confirmed_at).to eq(send_user.confirmed_at)
      end
    end

    # let(:not_redirect_url) { 'http://www.example.com://' }
    shared_examples_for 'ToOK(html)' do |alert, notice|
      let(:subject_format) { nil }
      it '[リダイレクトURLがある]指定URL（成功パラメータ）にリダイレクトする' do
        @redirect_url = FRONT_SITE_URL
        # is_expected.to redirect_to(/^#{@redirect_url}\?.*account_confirmation_success=true.*$/) # NOTE: ログイン中はaccess-token等も入る
        param = { account_confirmation_success: true }
        param[:alert] = I18n.t(alert) if alert.present?
        param[:notice] = I18n.t(notice) if notice.present?
        is_expected.to redirect_to("#{FRONT_SITE_URL}?#{URI.encode_www_form(param.sort)}")
      end
      it '[リダイレクトURLがない]成功ページにリダイレクトする' do
        @redirect_url = nil
        # is_expected.to redirect_to(/^#{not_redirect_url}\?.*account_confirmation_success=true.*$/) # NOTE: ログイン中はaccess-token等も入る
        is_expected.to redirect_to(Settings['confirmation_success_url_not'])
      end
      it '[リダイレクトURLがホワイトリストにない]成功ページにリダイレクトする' do
        @redirect_url = BAD_SITE_URL
        # is_expected.to redirect_to(/^#{@redirect_url}\?.*account_confirmation_success=true.*$/) # NOTE: ログイン中はaccess-token等も入る
        is_expected.to redirect_to(Settings['confirmation_success_url_bad'])
      end
    end
    shared_examples_for 'ToNG(html)' do |alert, notice|
      let(:subject_format) { nil }
      it '[リダイレクトURLがある]指定URL（失敗パラメータ）にリダイレクトする' do
        @redirect_url = FRONT_SITE_URL
        param = { account_confirmation_success: false }
        param[:alert] = I18n.t(alert) if alert.present?
        param[:notice] = I18n.t(notice) if notice.present?
        is_expected.to redirect_to("#{FRONT_SITE_URL}?#{URI.encode_www_form(param.sort)}")
      end
      it '[リダイレクトURLがない]エラーページにリダイレクトする' do
        @redirect_url = nil
        # is_expected.to redirect_to(/^#{not_redirect_url}\?.*account_confirmation_success=true.*$/) # NOTE: ログイン中はaccess-token等も入る
        is_expected.to redirect_to(Settings['confirmation_error_url_not'])
      end
      it '[リダイレクトURLがホワイトリストにない]エラーページにリダイレクトする' do
        @redirect_url = BAD_SITE_URL
        # is_expected.to redirect_to(/^#{BAD_SITE_URL}\?.*account_confirmation_success=true.*$/) # NOTE: ログイン中はaccess-token等も入る
        is_expected.to redirect_to(Settings['confirmation_error_url_bad'])
      end
    end

    shared_examples_for 'ToOK(html/html)' do |alert, notice|
      let(:accept_headers) { ACCEPT_INC_HTML }
      it_behaves_like 'ToOK(html)', alert, notice
    end
    shared_examples_for 'ToOK(html/json)' do |alert, notice|
      let(:accept_headers) { ACCEPT_INC_JSON }
      it_behaves_like 'ToOK(html)', alert, notice
    end
    shared_examples_for 'ToNG(html/html)' do |alert, notice|
      let(:accept_headers) { ACCEPT_INC_HTML }
      it_behaves_like 'ToNG(html)', alert, notice
    end
    shared_examples_for 'ToNG(html/json)' do |alert, notice|
      let(:accept_headers) { ACCEPT_INC_JSON }
      it_behaves_like 'ToNG(html)', alert, notice
    end

    shared_examples_for 'ToOK' do |alert, notice|
      it_behaves_like 'ToOK(html/html)', alert, notice
      it_behaves_like 'ToOK(html/json)', alert, notice
      it_behaves_like 'To406(json/html)'
      it_behaves_like 'To406(json/json)'
    end
    shared_examples_for 'ToNG' do |alert, notice|
      it_behaves_like 'ToNG(html/html)', alert, notice
      it_behaves_like 'ToNG(html/json)', alert, notice
      it_behaves_like 'To406(json/html)'
      it_behaves_like 'To406(json/json)'
    end

    # テストケース
    shared_examples_for '[未ログイン][期限内]確認日時がない（未確認）' do
      include_context 'メールアドレス確認トークン作成', false, nil
      it_behaves_like 'OK'
      it_behaves_like 'ToOK', nil, 'devise.confirmations.confirmed'
    end
    shared_examples_for '[ログイン中][期限内]確認日時がない（未確認）' do # NOTE: ログイン中も出来ても良さそう
      include_context 'メールアドレス確認トークン作成', false, nil
      it_behaves_like 'OK'
      it_behaves_like 'ToOK', nil, 'devise.confirmations.confirmed'
    end
    shared_examples_for '[*][期限切れ]確認日時がない（未確認）' do
      include_context 'メールアドレス確認トークン作成', false, nil
      # it_behaves_like 'NG' # NOTE: ActionController::RoutingError: Not Found
      it_behaves_like 'NG'
      it_behaves_like 'ToNG', 'activerecord.errors.models.user.attributes.confirmation_token.invalid', nil
    end
    shared_examples_for '[*][存在しない/ない/空]確認日時がない（未確認）' do
      # it_behaves_like 'NG' # NOTE: ActionController::RoutingError: Not Found
      # it_behaves_like 'NG' # NOTE: トークンが存在しない為、確認日時がない
      it_behaves_like 'ToNG', 'activerecord.errors.models.user.attributes.confirmation_token.invalid', nil
    end
    shared_examples_for '[未ログイン][期限内]確認日時が確認送信日時より前（未確認）' do
      include_context 'メールアドレス確認トークン作成', true, true
      it_behaves_like 'OK'
      it_behaves_like 'ToOK', nil, 'devise.confirmations.confirmed'
    end
    shared_examples_for '[ログイン中][期限内]確認日時が確認送信日時より前（未確認）' do # NOTE: ログイン中も出来ても良さそう
      include_context 'メールアドレス確認トークン作成', true, true
      it_behaves_like 'OK'
      it_behaves_like 'ToOK', nil, 'devise.confirmations.confirmed'
    end
    shared_examples_for '[*][期限切れ]確認日時が確認送信日時より前（未確認）' do
      include_context 'メールアドレス確認トークン作成', true, true
      # it_behaves_like 'NG' # NOTE: ActionController::RoutingError: Not Found
      it_behaves_like 'NG'
      it_behaves_like 'ToNG', 'activerecord.errors.models.user.attributes.confirmation_token.invalid', nil
    end
    shared_examples_for '[*][期限内]確認日時が確認送信日時より後（確認済み）' do
      include_context 'メールアドレス確認トークン作成', true, false
      # it_behaves_like 'NG' # NOTE: ActionController::RoutingError: Not Found
      it_behaves_like 'NG'
      it_behaves_like 'ToOK', 'errors.messages.already_confirmed', nil
    end
    shared_examples_for '[*][期限切れ]確認日時が確認送信日時より後（確認済み）' do
      include_context 'メールアドレス確認トークン作成', true, false
      # it_behaves_like 'NG' # NOTE: ActionController::RoutingError: Not Found
      it_behaves_like 'NG'
      it_behaves_like 'ToOK', 'errors.messages.already_confirmed', nil
    end

    shared_examples_for '[未ログイン]トークンが期限内' do
      let_it_be(:confirmation_sent_at) { Time.now.utc }
      it_behaves_like '[未ログイン][期限内]確認日時がない（未確認）'
      it_behaves_like '[未ログイン][期限内]確認日時が確認送信日時より前（未確認）'
      it_behaves_like '[*][期限内]確認日時が確認送信日時より後（確認済み）'
    end
    shared_examples_for '[ログイン中]トークンが期限内' do
      let_it_be(:confirmation_sent_at) { Time.now.utc }
      it_behaves_like '[ログイン中][期限内]確認日時がない（未確認）'
      it_behaves_like '[ログイン中][期限内]確認日時が確認送信日時より前（未確認）'
      it_behaves_like '[*][期限内]確認日時が確認送信日時より後（確認済み）'
    end
    shared_examples_for '[*]トークンが期限切れ' do
      let_it_be(:confirmation_sent_at) { Time.now.utc - User.confirm_within - 1.hour }
      it_behaves_like '[*][期限切れ]確認日時がない（未確認）'
      it_behaves_like '[*][期限切れ]確認日時が確認送信日時より前（未確認）'
      it_behaves_like '[*][期限切れ]確認日時が確認送信日時より後（確認済み）'
    end
    shared_examples_for '[*]トークンが存在しない' do
      let(:confirmation_token) { NOT_TOKEN }
      it_behaves_like '[*][存在しない/ない/空]確認日時がない（未確認）'
      # it_behaves_like '[*][存在しない]確認日時が確認送信日時より前（未確認）' # NOTE: トークンが存在しない為、確認日時がない
      # it_behaves_like '[*][存在しない]確認日時が確認送信日時より後（確認済み）' # NOTE: トークンが存在しない為、確認日時がない
    end
    shared_examples_for '[*]トークンがない' do
      let(:confirmation_token) { nil }
      it_behaves_like '[*][存在しない/ない/空]確認日時がない（未確認）'
      # it_behaves_like '[*][ない]確認日時が確認送信日時より前（未確認）' # NOTE: トークンが存在しない為、確認日時がない
      # it_behaves_like '[*][ない]確認日時が確認送信日時より後（確認済み）' # NOTE: トークンが存在しない為、確認日時がない
    end
    shared_examples_for '[*]トークンが空' do
      let(:confirmation_token) { '' }
      it_behaves_like '[*][存在しない/ない/空]確認日時がない（未確認）'
      # it_behaves_like '[*][空]確認日時が確認送信日時より前（未確認）' # NOTE: トークンが存在しない為、確認日時がない
      # it_behaves_like '[*][空]確認日時が確認送信日時より後（確認済み）' # NOTE: トークンが存在しない為、確認日時がない
    end

    context '未ログイン' do
      include_context '未ログイン処理'
      it_behaves_like '[未ログイン]トークンが期限内'
      it_behaves_like '[*]トークンが期限切れ'
      it_behaves_like '[*]トークンが存在しない'
      it_behaves_like '[*]トークンがない'
      it_behaves_like '[*]トークンが空'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[ログイン中]トークンが期限内'
      it_behaves_like '[*]トークンが期限切れ'
      it_behaves_like '[*]トークンが存在しない'
      it_behaves_like '[*]トークンがない'
      it_behaves_like '[*]トークンが空'
    end
    context 'APIログイン中' do
      include_context 'APIログイン処理'
      it_behaves_like '[ログイン中]トークンが期限内'
      it_behaves_like '[*]トークンが期限切れ'
      it_behaves_like '[*]トークンが存在しない'
      it_behaves_like '[*]トークンがない'
      it_behaves_like '[*]トークンが空'
    end
  end
end
