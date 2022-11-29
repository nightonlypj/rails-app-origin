require 'rails_helper'

RSpec.describe 'Users::Auth::Unlocks', type: :request do
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

  # POST /users/auth/unlock(.json) アカウントロック解除API[メール再送](処理)
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, APIログイン中
  #   パラメータなし, 有効なパラメータ（ロック中, 未ロック）, 無効なパラメータ, URLがない, URLがホワイトリストにない
  #   ＋URLの拡張子: .json, ない
  #   ＋Acceptヘッダ: JSONが含まれる, JSONが含まれない
  describe 'POST #create' do
    subject { post create_user_auth_unlock_path(format: subject_format), params: attributes, headers: auth_headers.merge(accept_headers) }
    let_it_be(:send_user_locked)   { FactoryBot.create(:user, :locked) }
    let_it_be(:send_user_unlocked) { FactoryBot.create(:user) }
    let_it_be(:not_user)           { FactoryBot.attributes_for(:user) }
    let(:valid_attributes)       { { email: send_user.email, redirect_url: FRONT_SITE_URL } }
    let(:invalid_attributes)     { { email: not_user[:email], redirect_url: FRONT_SITE_URL } }
    let(:invalid_nil_attributes) { { email: send_user_locked.email, redirect_url: nil } }
    let(:invalid_bad_attributes) { { email: send_user_locked.email, redirect_url: BAD_SITE_URL } }
    include_context 'Authテスト内容'
    let(:current_user) { nil }

    # テスト内容
    shared_examples_for 'OK' do
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      let(:url)       { "http://#{Settings['base_domain']}#{user_auth_unlock_path}" }
      let(:url_param) { "redirect_url=#{URI.encode_www_form_component(attributes[:redirect_url])}" }
      it 'メールが送信される' do
        subject
        expect(ActionMailer::Base.deliveries.count).to eq(1)
        expect(ActionMailer::Base.deliveries[0].subject).to eq(get_subject('devise.mailer.unlock_instructions.subject')) # アカウントロックのお知らせ
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
        expect(response_json['success']).to eq(false)
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
    shared_examples_for '[未ログイン/ログイン中]パラメータなし' do
      let(:attributes) { nil }
      it_behaves_like 'NG'
      # it_behaves_like 'ToNG', 422
      it_behaves_like 'ToNG', 400
      # it_behaves_like 'ToMsg', Array, 1, 'devise_token_auth.unlocks.not_allowed_redirect_url', nil, nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'errors.messages.validate_unlock_params', nil
    end
    shared_examples_for '[APIログイン中]パラメータなし' do
      let(:attributes) { nil }
      it_behaves_like 'NG'
      # it_behaves_like 'ToNG', 422
      it_behaves_like 'ToNG', 401
      # it_behaves_like 'ToMsg', Array, 1, 'devise_token_auth.unlocks.not_allowed_redirect_url', nil, nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン/ログイン中]有効なパラメータ（ロック中）' do
      let(:send_user)  { send_user_locked }
      let(:attributes) { valid_attributes }
      it_behaves_like 'OK'
      it_behaves_like 'ToOK', nil, 'devise.unlocks.send_instructions'
      # it_behaves_like 'ToMsg', NilClass, 0, nil, 'devise_token_auth.unlocks.sended', nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, nil, 'devise_token_auth.unlocks.sended'
    end
    shared_examples_for '[APIログイン中]有効なパラメータ（ロック中）' do
      let(:send_user)  { send_user_locked }
      let(:attributes) { valid_attributes }
      # it_behaves_like 'OK'
      it_behaves_like 'NG'
      # it_behaves_like 'ToOK'
      it_behaves_like 'ToNG', 401
      # it_behaves_like 'ToMsg', NilClass, 0, nil, 'devise_token_auth.unlocks.sended', nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン/ログイン中]有効なパラメータ（未ロック）' do
      let(:send_user)  { send_user_unlocked }
      let(:attributes) { valid_attributes }
      # it_behaves_like 'OK'
      it_behaves_like 'NG'
      # it_behaves_like 'ToOK'
      it_behaves_like 'ToNG', 422
      # it_behaves_like 'ToMsg', NilClass, 0, nil, 'devise_token_auth.unlocks.sended', nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'errors.messages.not_locked', nil
    end
    shared_examples_for '[APIログイン中]有効なパラメータ（未ロック）' do
      let(:send_user)  { send_user_unlocked }
      let(:attributes) { valid_attributes }
      # it_behaves_like 'OK'
      it_behaves_like 'NG'
      # it_behaves_like 'ToOK'
      it_behaves_like 'ToNG', 401
      # it_behaves_like 'ToMsg', NilClass, 0, nil, 'devise_token_auth.unlocks.sended', nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン/ログイン中]無効なパラメータ' do
      let(:attributes) { invalid_attributes }
      it_behaves_like 'NG'
      # it_behaves_like 'ToNG', 404
      it_behaves_like 'ToNG', 422
      # it_behaves_like 'ToMsg', Array, 1, 'devise_token_auth.unlocks.user_not_found', nil, nil, nil
      it_behaves_like 'ToMsg', Hash, 2, 'devise_token_auth.unlocks.user_not_found', nil, 'errors.messages.not_saved.one', nil
    end
    shared_examples_for '[APIログイン中]無効なパラメータ' do
      let(:attributes) { invalid_attributes }
      it_behaves_like 'NG'
      # it_behaves_like 'ToNG', 404
      it_behaves_like 'ToNG', 401
      # it_behaves_like 'ToMsg', Array, 1, 'devise_token_auth.unlocks.user_not_found', nil, nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン/ログイン中]URLがない' do
      let(:attributes) { invalid_nil_attributes }
      it_behaves_like 'NG'
      # it_behaves_like 'ToNG', 401
      it_behaves_like 'ToNG', 422
      # it_behaves_like 'ToMsg', Array, 1, 'devise_token_auth.unlocks.missing_redirect_url', nil, nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise_token_auth.unlocks.missing_redirect_url', nil
    end
    shared_examples_for '[APIログイン中]URLがない' do
      let(:attributes) { invalid_nil_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToNG', 401
      # it_behaves_like 'ToMsg', Array, 1, 'devise_token_auth.unlocks.missing_redirect_url', nil, nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン/ログイン中]URLがホワイトリストにない' do
      let(:attributes) { invalid_bad_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToNG', 422
      # it_behaves_like 'ToMsg', Array, 1, 'devise_token_auth.unlocks.not_allowed_redirect_url', nil, nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise_token_auth.unlocks.not_allowed_redirect_url', nil
    end
    shared_examples_for '[APIログイン中]URLがホワイトリストにない' do
      let(:attributes) { invalid_bad_attributes }
      it_behaves_like 'NG'
      # it_behaves_like 'ToNG', 422
      it_behaves_like 'ToNG', 401
      # it_behaves_like 'ToMsg', Array, 1, 'devise_token_auth.unlocks.not_allowed_redirect_url', nil, nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise.failure.already_authenticated', nil
    end

    context '未ログイン' do
      include_context '未ログイン処理'
      it_behaves_like '[未ログイン/ログイン中]パラメータなし'
      it_behaves_like '[未ログイン/ログイン中]有効なパラメータ（ロック中）'
      it_behaves_like '[未ログイン/ログイン中]有効なパラメータ（未ロック）'
      it_behaves_like '[未ログイン/ログイン中]無効なパラメータ'
      it_behaves_like '[未ログイン/ログイン中]URLがない'
      it_behaves_like '[未ログイン/ログイン中]URLがホワイトリストにない'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[未ログイン/ログイン中]パラメータなし'
      it_behaves_like '[未ログイン/ログイン中]有効なパラメータ（ロック中）'
      it_behaves_like '[未ログイン/ログイン中]有効なパラメータ（未ロック）'
      it_behaves_like '[未ログイン/ログイン中]無効なパラメータ'
      it_behaves_like '[未ログイン/ログイン中]URLがない'
      it_behaves_like '[未ログイン/ログイン中]URLがホワイトリストにない'
    end
    context 'APIログイン中' do
      include_context 'APIログイン処理'
      it_behaves_like '[APIログイン中]パラメータなし'
      it_behaves_like '[APIログイン中]有効なパラメータ（ロック中）'
      it_behaves_like '[APIログイン中]有効なパラメータ（未ロック）'
      it_behaves_like '[APIログイン中]無効なパラメータ'
      it_behaves_like '[APIログイン中]URLがない'
      it_behaves_like '[APIログイン中]URLがホワイトリストにない'
    end
  end

  # GET /users/auth/unlock アカウントロック解除(処理)
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, APIログイン中
  #   トークン: 存在する, 存在しない, ない, 空
  #   ロック日時: ない（未ロック）, 期限内（ロック中）, 期限切れ（未ロック）
  #   ＋URLの拡張子: ない, .json
  #   ＋Acceptヘッダ: JSONが含まれない, JSONが含まれる
  #   ＋リダイレクトURL: ある, ない, ホワイトリストにない
  describe 'GET #show' do
    subject do
      get user_auth_unlock_path(format: subject_format, unlock_token: unlock_token, redirect_url: @redirect_url), headers: auth_headers.merge(accept_headers)
    end
    let(:current_user) { User.find(send_user.id) }

    # テスト内容
    shared_examples_for 'OK' do
      let(:subject_format) { nil }
      let(:accept_headers) { ACCEPT_INC_HTML }
      it '[リダイレクトURLがある]アカウントロック日時がなしに回数が0に変更される' do
        @redirect_url = FRONT_SITE_URL
        subject
        expect(current_user.locked_at).to be_nil
        expect(current_user.failed_attempts).to eq(0)
      end
      # it '[リダイレクトURLがない]アカウントロック日時がなしに変更されない' do
      it '[リダイレクトURLがない]アカウントロック日時がなしに回数が0に変更される' do
        @redirect_url = nil
        subject
        # expect(current_user.locked_at).to eq(send_user.locked_at)
        # expect(current_user.failed_attempts).to eq(send_user.failed_attempts)
        expect(current_user.locked_at).to be_nil
        expect(current_user.failed_attempts).to eq(0)
      end
      # it '[リダイレクトURLがホワイトリストにない]アカウントロック日時がなしに変更されない' do
      it '[リダイレクトURLがホワイトリストにない]アカウントロック日時がなしに回数が0に変更される' do
        @redirect_url = BAD_SITE_URL
        subject
        # expect(current_user.locked_at).to eq(send_user.locked_at)
        # expect(current_user.failed_attempts).to eq(send_user.failed_attempts)
        expect(current_user.locked_at).to be_nil
        expect(current_user.failed_attempts).to eq(0)
      end
    end
    shared_examples_for 'NG' do
      let(:subject_format) { nil }
      let(:accept_headers) { ACCEPT_INC_HTML }
      it '[リダイレクトURLがある]アカウントロック日時・回数が変更されない' do
        @redirect_url = FRONT_SITE_URL
        subject
        expect(current_user.locked_at).to eq(send_user.locked_at)
        expect(current_user.failed_attempts).to eq(send_user.failed_attempts)
      end
      it '[リダイレクトURLがない]アカウントロック日時・回数が変更されない' do
        @redirect_url = nil
        subject
        expect(current_user.locked_at).to eq(send_user.locked_at)
        expect(current_user.failed_attempts).to eq(send_user.failed_attempts)
      end
      it '[リダイレクトURLがホワイトリストにない]アカウントロック日時・回数が変更されない' do
        @redirect_url = BAD_SITE_URL
        subject
        expect(current_user.locked_at).to eq(send_user.locked_at)
        expect(current_user.failed_attempts).to eq(send_user.failed_attempts)
      end
    end

    shared_examples_for 'ToOK(html)' do |alert, notice|
      let(:subject_format) { nil }
      it '[リダイレクトURLがある]指定URL（成功パラメータ）にリダイレクトする' do
        @redirect_url = FRONT_SITE_URL
        param = { unlock: true }
        param[:alert] = I18n.t(alert) if alert.present?
        param[:notice] = I18n.t(notice) if notice.present?
        is_expected.to redirect_to("#{FRONT_SITE_URL}?#{URI.encode_www_form(param.sort)}")
      end
      # it '[リダイレクトURLがない]HTTPステータスが422。対象項目が一致する' do
      it '[リダイレクトURLがない]成功ページにリダイレクトする' do
        @redirect_url = nil
        # is_expected.to eq(422)
        # expect(response_json['success']).to eq(false)
        # expect(response_json['errors']).not_to be_nil
        # expect(response_json['message']).to be_nil
        is_expected.to redirect_to(Settings['unlock_success_url_not'])
      end
      # it '[リダイレクトURLがホワイトリストにない]HTTPステータスが422。対象項目が一致する' do
      it '[リダイレクトURLがホワイトリストにない]成功ページにリダイレクトする' do
        @redirect_url = BAD_SITE_URL
        # is_expected.to eq(422)
        # expect(response_json['success']).to eq(false)
        # expect(response_json['errors']).not_to be_nil
        # expect(response_json['message']).to be_nil
        is_expected.to redirect_to(Settings['unlock_success_url_bad'])
      end
    end
    shared_examples_for 'ToNG(html)' do |alert, notice|
      let(:subject_format) { nil }
      it '[リダイレクトURLがある]指定URL（失敗パラメータ）にリダイレクトする' do
        @redirect_url = FRONT_SITE_URL
        param = { unlock: false }
        param[:alert] = I18n.t(alert) if alert.present?
        param[:notice] = I18n.t(notice) if notice.present?
        is_expected.to redirect_to("#{FRONT_SITE_URL}?#{URI.encode_www_form(param.sort)}")
      end
      # it '[リダイレクトURLがない]HTTPステータスが422。対象項目が一致する' do
      it '[リダイレクトURLがない]エラーページにリダイレクトする' do
        @redirect_url = nil
        # is_expected.to eq(422)
        # expect(response_json['success']).to eq(false)
        # expect(response_json['errors']).not_to be_nil
        # expect(response_json['message']).to be_nil
        is_expected.to redirect_to(Settings['unlock_error_url_not'])
      end
      # it '[リダイレクトURLがホワイトリストにない]HTTPステータスが422。対象項目が一致する' do
      it '[リダイレクトURLがホワイトリストにない]エラーページにリダイレクトする' do
        @redirect_url = BAD_SITE_URL
        # is_expected.to eq(422)
        # expect(response_json['success']).to eq(false)
        # expect(response_json['errors']).not_to be_nil
        # expect(response_json['message']).to be_nil
        is_expected.to redirect_to(Settings['unlock_error_url_bad'])
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
    shared_examples_for '[*][存在する]ロック日時がない（未ロック）' do
      include_context 'アカウントロック解除トークン作成', false
      it_behaves_like 'NG'
      # it_behaves_like 'ToOK', nil, nil
      it_behaves_like 'ToOK', nil, 'devise.unlocks.unlocked' # NOTE: 既に解除済み
    end
    shared_examples_for '[*][存在しない]ロック日時がない（未ロック）' do
      # it_behaves_like 'NG' # NOTE: トークンが存在しない為、ロック日時がない
      # it_behaves_like 'ToNG', nil, nil # NOTE: ActionController::RoutingError: Not Found
      it_behaves_like 'ToNG', 'activerecord.errors.models.user.attributes.unlock_token.invalid', nil
    end
    shared_examples_for '[*][ない/空]ロック日時がない（未ロック）' do
      # it_behaves_like 'NG' # NOTE: トークンが存在しない為、ロック日時がない
      # it_behaves_like 'ToNG', nil, nil # NOTE: ActionController::RoutingError: Not Found
      it_behaves_like 'ToNG', 'activerecord.errors.models.user.attributes.unlock_token.blank', nil
    end
    shared_examples_for '[*][存在する]ロック日時が期限内（ロック中）' do
      include_context 'アカウントロック解除トークン作成', true
      it_behaves_like 'OK'
      it_behaves_like 'ToOK', nil, 'devise.unlocks.unlocked' # NOTE: 解除されても良さそう
    end
    shared_examples_for '[*][存在する]ロック日時が期限切れ（未ロック）' do
      include_context 'アカウントロック解除トークン作成', true, true
      it_behaves_like 'OK'
      it_behaves_like 'ToOK', nil, 'devise.unlocks.unlocked'
    end

    shared_examples_for '[*]トークンが存在する' do
      it_behaves_like '[*][存在する]ロック日時がない（未ロック）'
      it_behaves_like '[*][存在する]ロック日時が期限内（ロック中）'
      it_behaves_like '[*][存在する]ロック日時が期限切れ（未ロック）'
    end
    shared_examples_for '[*]トークンが存在しない' do
      let(:unlock_token) { NOT_TOKEN }
      it_behaves_like '[*][存在しない]ロック日時がない（未ロック）'
      # it_behaves_like '[*][存在しない]ロック日時が期限内（ロック中）' # NOTE: トークンが存在しない為、ロック日時がない
      # it_behaves_like '[*][存在しない]ロック日時が期限切れ（未ロック）' # NOTE: トークンが存在しない為、ロック日時がない
    end
    shared_examples_for '[*]トークンがない' do
      let(:unlock_token) { nil }
      it_behaves_like '[*][ない/空]ロック日時がない（未ロック）'
      # it_behaves_like '[*][ない]ロック日時が期限内（ロック中）' # NOTE: トークンが存在しない為、ロック日時がない
      # it_behaves_like '[*][ない]ロック日時が期限切れ（未ロック）' # NOTE: トークンが存在しない為、ロック日時がない
    end
    shared_examples_for '[*]トークンが空' do
      let(:unlock_token) { '' }
      it_behaves_like '[*][ない/空]ロック日時がない（未ロック）'
      # it_behaves_like '[*][空]ロック日時が期限内（ロック中）' # NOTE: トークンが存在しない為、ロック日時がない
      # it_behaves_like '[*][空]ロック日時が期限切れ（未ロック）' # NOTE: トークンが存在しない為、ロック日時がない
    end

    context '未ログイン' do
      include_context '未ログイン処理'
      it_behaves_like '[*]トークンが存在する'
      it_behaves_like '[*]トークンが存在しない'
      it_behaves_like '[*]トークンがない'
      it_behaves_like '[*]トークンが空'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[*]トークンが存在する'
      it_behaves_like '[*]トークンが存在しない'
      it_behaves_like '[*]トークンがない'
      it_behaves_like '[*]トークンが空'
    end
    context 'APIログイン中' do
      include_context 'APIログイン処理'
      it_behaves_like '[*]トークンが存在する'
      it_behaves_like '[*]トークンが存在しない'
      it_behaves_like '[*]トークンがない'
      it_behaves_like '[*]トークンが空'
    end
  end
end
