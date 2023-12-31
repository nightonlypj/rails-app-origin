require 'rails_helper'

RSpec.describe 'Users::Auth::Registrations', type: :request do
  let(:response_json) { JSON.parse(response.body) }

  # テスト内容（共通）
  shared_examples_for 'ToMsg' do |error_class, errors_count, error_msg, message, alert, notice|
    let(:subject_format) { :json }
    let(:accept_headers) { ACCEPT_INC_JSON }
    it '対象のメッセージと一致する' do
      subject
      expect(response_json['errors'].to_s).to error_msg.present? ? include(get_locale(error_msg)) : be_blank
      expect(response_json['errors'].class).to eq(error_class) # 方針: バリデーション(Hash)のみ、他はalertへ
      expect(response_json['errors']&.count).to errors_count > 0 ? eq(errors_count) : be_nil
      expect(response_json['message']).to message.present? ? eq(get_locale(message)) : be_nil # 方針: 廃止して、noticeへ
      expect(response_json['alert']).to alert.present? ? eq(get_locale(alert)) : be_nil # 方針: 追加
      expect(response_json['notice']).to notice.present? ? eq(get_locale(notice)) : be_nil # 方針: 追加
    end
  end

  # POST /users/auth/sign_up(.json) アカウント登録API(処理)
  # テストパターン
  #   未ログイン, ログイン中, APIログイン中
  #   パラメータなし, 有効なパラメータ, 無効なパラメータ, URLがない, URLがホワイトリストにない
  #   ＋URLの拡張子: .json, ない
  #   ＋Acceptヘッダ: JSONが含まれる, JSONが含まれない
  describe 'POST #create' do
    subject { post create_user_auth_registration_path(format: subject_format), params:, headers: auth_headers.merge(accept_headers) }
    let_it_be(:new_user)   { FactoryBot.attributes_for(:user) }
    let_it_be(:exist_user) { FactoryBot.create(:user) }
    let(:valid_attributes)       { { name: new_user[:name], email: new_user[:email], password: new_user[:password], confirm_success_url: FRONT_SITE_URL } }
    let(:invalid_attributes)     { { name: exist_user.name, email: exist_user.email, password: exist_user.password, confirm_success_url: FRONT_SITE_URL } }
    let(:invalid_attributes_nil) { { name: new_user[:name], email: new_user[:email], password: new_user[:password], confirm_success_url: nil } }
    let(:invalid_attributes_bad) { { name: new_user[:name], email: new_user[:email], password: new_user[:password], confirm_success_url: BAD_SITE_URL } }

    # テスト内容
    let(:current_user) { User.last }
    include_context 'Authテスト内容'

    shared_examples_for 'OK' do
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      let(:url)       { "http://#{Settings.base_domain}#{user_auth_confirmation_path}" }
      let(:url_param) { "redirect_url=#{URI.encode_www_form_component(params[:confirm_success_url])}" }
      it 'ユーザーが作成・対象項目が設定される。メールが送信される' do
        expect do
          subject
          expect(current_user.email).to eq(params[:email])
          expect(current_user.name).to eq(params[:name])

          expect(ActionMailer::Base.deliveries.count).to eq(1)
          expect(ActionMailer::Base.deliveries[0].subject).to eq(get_subject('devise.mailer.confirmation_instructions.subject')) # メールアドレス確認のお願い
          expect(ActionMailer::Base.deliveries[0].html_part.body).to include(url)
          expect(ActionMailer::Base.deliveries[0].text_part.body).to include(url)
          expect(ActionMailer::Base.deliveries[0].html_part.body).to include(url_param)
          expect(ActionMailer::Base.deliveries[0].text_part.body).to include(url_param)
        end.to change(User, :count).by(1)
      end
    end
    shared_examples_for 'NG' do
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      it '作成されない。メールが送信されない' do
        expect { subject }.to change(User, :count).by(0) && change(ActionMailer::Base.deliveries, :count).by(0)
      end
    end

    shared_examples_for 'ToOK(json/json)' do # |status, success, data_present|
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      it 'HTTPステータスが200。対象項目が一致する。認証ヘッダがない' do
        is_expected.to eq(200)
        # expect(response_json['status']).to eq(status) # 方針: 廃止して、successに統一
        # expect(response_json['success']).to eq(success)
        # expect(response_json['data'].present?).to eq(data_present) # 方針: 廃止
        expect_success_json
        expect_not_exist_auth_header
      end
    end
    shared_examples_for 'ToNG(json/json)' do |code| # , status, success, data_present|
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      it "HTTPステータスが#{code}。対象項目が一致する。認証ヘッダがない" do
        is_expected.to eq(code) # 方針(優先順): 401: ログイン中, 400:パラメータなし, 422: 無効なパラメータ・状態
        # expect(response_json['status']).to eq(status) # 方針: 廃止して、successに統一
        # expect(response_json['success']).to eq(success)
        # expect(response_json['data'].present?).to eq(data_present) # 方針: 廃止
        expect_failure_json
        expect_not_exist_auth_header
      end
    end

    shared_examples_for 'ToOK' do # |status, success, data_present|
      it_behaves_like 'ToNG(html/html)', 406
      it_behaves_like 'ToNG(html/json)', 406
      it_behaves_like 'ToNG(json/html)', 406
      it_behaves_like 'ToOK(json/json)' # , status, success, data_present
    end
    shared_examples_for 'ToNG' do |code| # , status, success, data_present|
      it_behaves_like 'ToNG(html/html)', 406
      it_behaves_like 'ToNG(html/json)', 406
      it_behaves_like 'ToNG(json/html)', 406
      it_behaves_like 'ToNG(json/json)', code # , status, success, data_present
    end

    # テストケース
    shared_examples_for '[未ログイン/ログイン中]パラメータなし' do
      let(:params) { nil }
      it_behaves_like 'NG'
      # it_behaves_like 'ToNG', 422, 'error', false, false
      it_behaves_like 'ToNG', 400, nil, false, false
      # it_behaves_like 'ToMsg', Array, 1, 'errors.messages.validate_sign_up_params', nil, nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'errors.messages.validate_sign_up_params', nil
    end
    shared_examples_for '[APIログイン中]パラメータなし' do
      let(:params) { nil }
      it_behaves_like 'NG'
      # it_behaves_like 'ToNG', 422, 'error', false, false
      it_behaves_like 'ToNG', 401, nil, false, false
      # it_behaves_like 'ToMsg', Array, 1, 'errors.messages.validate_sign_up_params', nil, nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン/ログイン中]有効なパラメータ' do
      let(:params) { valid_attributes }
      it_behaves_like 'OK'
      # it_behaves_like 'ToOK', 'success', nil, true
      it_behaves_like 'ToOK', nil, true, false
      # it_behaves_like 'ToMsg', NilClass, 0, nil, nil, nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, nil, 'devise.registrations.signed_up_but_unconfirmed'
    end
    shared_examples_for '[APIログイン中]有効なパラメータ' do
      let(:params) { valid_attributes }
      # it_behaves_like 'OK'
      it_behaves_like 'NG'
      # it_behaves_like 'ToOK', 'success', nil, true
      it_behaves_like 'ToNG', 401, nil, false, false
      # it_behaves_like 'ToMsg', NilClass, 0, nil, nil, nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン/ログイン中]無効なパラメータ' do
      let(:params) { invalid_attributes }
      it_behaves_like 'NG'
      # it_behaves_like 'ToNG', 422, 'error', nil, true
      it_behaves_like 'ToNG', 422, nil, false, false
      # it_behaves_like 'ToMsg', Hash, 2, 'activerecord.errors.models.user.attributes.email.taken', nil, nil, nil
      it_behaves_like 'ToMsg', Hash, 2, 'activerecord.errors.models.user.attributes.email.taken', nil, 'errors.messages.not_saved.one', nil
    end
    shared_examples_for '[APIログイン中]無効なパラメータ' do
      let(:params) { invalid_attributes }
      it_behaves_like 'NG'
      # it_behaves_like 'ToNG', 422, 'error', nil, true
      it_behaves_like 'ToNG', 401, nil, false, false
      # it_behaves_like 'ToMsg', Hash, 2, 'activerecord.errors.models.user.attributes.email.taken', nil, nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン/ログイン中]URLがない' do
      let(:params) { invalid_attributes_nil }
      it_behaves_like 'NG'
      # it_behaves_like 'ToNG', 422, 'error', false, true
      it_behaves_like 'ToNG', 422, nil, false, false
      # it_behaves_like 'ToMsg', Array, 1, 'devise_token_auth.registrations.missing_confirm_success_url', nil, nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise_token_auth.registrations.missing_confirm_success_url', nil
    end
    shared_examples_for '[APIログイン中]URLがない' do
      let(:params) { invalid_attributes_nil }
      it_behaves_like 'NG'
      # it_behaves_like 'ToNG', 422, 'error', false, true
      it_behaves_like 'ToNG', 401, nil, false, false
      # it_behaves_like 'ToMsg', Array, 1, 'devise_token_auth.registrations.missing_confirm_success_url', nil, nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン/ログイン中]URLがホワイトリストにない' do
      let(:params) { invalid_attributes_bad }
      it_behaves_like 'NG'
      # it_behaves_like 'ToNG', 422, 'error', false, true
      it_behaves_like 'ToNG', 422, nil, false, false
      # it_behaves_like 'ToMsg', Array, 1, 'devise_token_auth.registrations.redirect_url_not_allowed', nil, nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise_token_auth.registrations.redirect_url_not_allowed', nil
    end
    shared_examples_for '[APIログイン中]URLがホワイトリストにない' do
      let(:params) { invalid_attributes_bad }
      it_behaves_like 'NG'
      # it_behaves_like 'ToNG', 422, 'error', false, true
      it_behaves_like 'ToNG', 401, nil, false, false
      # it_behaves_like 'ToMsg', Array, 1, 'devise_token_auth.registrations.redirect_url_not_allowed', nil, nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise.failure.already_authenticated', nil
    end

    shared_examples_for '[未ログイン/ログイン中]' do
      it_behaves_like '[未ログイン/ログイン中]パラメータなし'
      it_behaves_like '[未ログイン/ログイン中]有効なパラメータ'
      it_behaves_like '[未ログイン/ログイン中]無効なパラメータ'
      it_behaves_like '[未ログイン/ログイン中]URLがない'
      it_behaves_like '[未ログイン/ログイン中]URLがホワイトリストにない'
    end

    context '未ログイン' do
      include_context '未ログイン処理'
      it_behaves_like '[未ログイン/ログイン中]'
    end
    context 'ログイン中' do
      include_context '未ログイン処理'
      it_behaves_like '[未ログイン/ログイン中]'
    end
    context 'APIログイン中' do
      include_context 'APIログイン処理'
      it_behaves_like '[APIログイン中]パラメータなし'
      it_behaves_like '[APIログイン中]有効なパラメータ'
      it_behaves_like '[APIログイン中]無効なパラメータ'
      it_behaves_like '[APIログイン中]URLがない'
      it_behaves_like '[APIログイン中]URLがホワイトリストにない'
    end
  end

  # GET /users/auth/detail(.json) ユーザー情報詳細API
  # テストパターン
  #   未ログイン, ログイン中, APIログイン中, APIログイン中（削除予約済み）
  #   ＋URLの拡張子: .json, ない
  #   ＋Acceptヘッダ: JSONが含まれる, JSONが含まれない
  describe 'GET #show' do
    subject { get show_user_auth_registration_path(format: subject_format), headers: auth_headers.merge(accept_headers) }

    # テスト内容
    let(:current_user) { user }
    include_context 'Authテスト内容'

    shared_examples_for 'ToOK(json/json)' do
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      let(:response_json_user) { response_json['user'] }
      it 'HTTPステータスが200。対象項目が一致する。認証ヘッダがある' do
        is_expected.to eq(200)
        expect(response_json['success']).to eq(true)

        count = expect_user_json(response_json_user, current_user, { email: true })
        expect(response_json_user['provider']).to eq(current_user.provider)
        ## Trackable
        expect(response_json_user['sign_in_count']).to eq(current_user.sign_in_count)
        expect(response_json_user['current_sign_in_at']).to eq(I18n.l(current_user.current_sign_in_at, format: :json, default: nil))
        expect(response_json_user['last_sign_in_at']).to eq(I18n.l(current_user.last_sign_in_at, format: :json, default: nil))
        expect(response_json_user['current_sign_in_ip']).to eq(current_user.current_sign_in_ip)
        expect(response_json_user['last_sign_in_ip']).to eq(current_user.last_sign_in_ip)
        ## Confirmable
        expect(response_json_user['unconfirmed_email']).to eq(current_user.unconfirmed_email.present? ? current_user.unconfirmed_email : nil)
        ## 作成日時
        expect(response_json_user['created_at']).to eq(I18n.l(current_user.created_at, format: :json))
        expect(response_json_user.count).to eq(count + 8)

        expect(response_json.count).to eq(2)
        expect_exist_auth_header
      end
    end
    shared_examples_for 'ToNG(json/json)' do |code|
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      it "HTTPステータスが#{code}。対象項目が一致する。認証ヘッダがない" do
        is_expected.to eq(code) # 方針(優先順): 401: 未ログイン
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

    shared_examples_for '[未ログイン/ログイン中]' do
      it_behaves_like 'ToNG', 401
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise.failure.unauthenticated', nil
    end
    shared_examples_for '[APIログイン中/削除予約済み]' do
      it_behaves_like 'ToOK'
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, nil, nil
    end

    # テストケース
    context '未ログイン' do
      include_context '未ログイン処理'
      it_behaves_like '[未ログイン/ログイン中]'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[未ログイン/ログイン中]'
    end
    context 'APIログイン中' do
      include_context 'APIログイン処理', :email_changed, true
      it_behaves_like '[APIログイン中/削除予約済み]'
    end
    context 'APIログイン中（削除予約済み）' do
      include_context 'APIログイン処理', :destroy_reserved, true
      it_behaves_like '[APIログイン中/削除予約済み]'
    end
  end

  # POST /users/auth/update(.json) ユーザー情報変更API(処理)
  # テストパターン
  #   未ログイン, ログイン中, APIログイン中, APIログイン中（削除予約済み）
  #   パラメータなし, 有効なパラメータ（変更なし, あり）, 無効なパラメータ, 現在のパスワードがない, URLがない, URLがホワイトリストにない
  #   ＋URLの拡張子: .json, ない
  #   ＋Acceptヘッダ: JSONが含まれる, JSONが含まれない
  describe 'POST #update' do
    subject { post update_user_auth_registration_path(format: subject_format), params:, headers: auth_headers.merge(accept_headers) }
    let_it_be(:new_user)   { FactoryBot.attributes_for(:user) }
    let_it_be(:exist_user) { FactoryBot.create(:user) }
    let(:nochange_attributes)    { { name: user.name, email: user.email, password: user.password, confirm_redirect_url: FRONT_SITE_URL } }
    let(:valid_attributes)       { { name: new_user[:name], email: new_user[:email], password: new_user[:password], confirm_redirect_url: FRONT_SITE_URL } }
    let(:invalid_attributes)     { { name: exist_user.name, email: exist_user.email, password: exist_user.password, confirm_redirect_url: FRONT_SITE_URL } }
    let(:invalid_attributes_nil) { { name: exist_user.name, email: exist_user.email, password: exist_user.password, confirm_redirect_url: nil } }
    let(:invalid_attributes_bad) { { name: exist_user.name, email: exist_user.email, password: exist_user.password, confirm_redirect_url: BAD_SITE_URL } }

    # テスト内容
    let(:current_user) { User.find(user.id) }
    include_context 'Authテスト内容'

    shared_examples_for 'OK' do |change_email|
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      let(:url)       { "http://#{Settings.base_domain}#{user_auth_confirmation_path}" }
      let(:url_param) { "redirect_url=#{URI.encode_www_form_component(params[:confirm_redirect_url])}" }
      it '対象項目が変更される。対象のメールが送信される' do
        subject
        expect(current_user.unconfirmed_email).to change_email ? eq(params[:email]) : eq(user.unconfirmed_email) # 確認待ちメールアドレス
        expect(current_user.name).to eq(params[:name]) # 氏名
        expect(current_user.image.url).to eq(user.image.url) # 画像 # NOTE: 変更されない

        expect(ActionMailer::Base.deliveries.count).to eq(change_email ? 3 : 1)
        expect(ActionMailer::Base.deliveries[0].subject).to eq(get_subject('devise.mailer.email_changed.subject')) if change_email # メールアドレス変更受け付けのお知らせ
        expect(ActionMailer::Base.deliveries[change_email ? 1 : 0].subject).to eq(get_subject('devise.mailer.password_change.subject')) # パスワード変更完了のお知らせ
        if change_email
          expect(ActionMailer::Base.deliveries[2].subject).to eq(get_subject('devise.mailer.confirmation_instructions.subject')) # メールアドレス確認のお願い
          expect(ActionMailer::Base.deliveries[2].html_part.body).to include(url)
          expect(ActionMailer::Base.deliveries[2].text_part.body).to include(url)
          expect(ActionMailer::Base.deliveries[2].html_part.body).to include(url_param)
          expect(ActionMailer::Base.deliveries[2].text_part.body).to include(url_param)
        end
      end
    end
    shared_examples_for 'NG' do
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      it '対象項目が変更されない。メールが送信されない' do
        subject
        expect(current_user.unconfirmed_email).to eq(user.unconfirmed_email) # 確認待ちメールアドレス
        expect(current_user.name).to eq(user.name) # 氏名
        expect(current_user.image.url).to eq(user.image.url) # 画像

        expect(ActionMailer::Base.deliveries.count).to eq(0)
      end
    end

    shared_examples_for 'ToOK(json/json)' do # |status, success, id_present|
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      it 'HTTPステータスが200。対象項目が一致する。認証ヘッダがある' do
        is_expected.to eq(200)
        # expect(response_json['status']).to eq(status) # 方針: 廃止して、successに統一
        # expect(response_json['success']).to eq(success)
        # expect(response_json['data']['id'].present?).to eq(id_present) # 方針: 廃止
        # expect(response_json['data']['name']).to eq(params[:name])
        # expect(response_json['data']['image']).not_to be_nil
        expect_success_json
        expect_exist_auth_header
      end
    end
    shared_examples_for 'ToNG(json/json)' do |code| # , status, success|
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      it "HTTPステータスが#{code}。対象項目が一致する。認証ヘッダがない" do
        is_expected.to eq(code) # 方針(優先順): 401: 未ログイン, 400:パラメータなし, 422: 無効なパラメータ・状態
        # expect(response_json['status']).to eq(status) # 方針: 廃止して、successに統一
        # expect(response_json['success']).to eq(success)
        # expect(response_json['data']).to be_nil
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
    shared_examples_for 'ToNG' do |code| # , status, success|
      it_behaves_like 'ToNG(html/html)', 406
      it_behaves_like 'ToNG(html/json)', 406
      it_behaves_like 'ToNG(json/html)', 406
      it_behaves_like 'ToNG(json/json)', code # , status, success
    end

    # テストケース
    shared_examples_for '[未ログイン/ログイン中]パラメータなし' do
      let(:params) { nil }
      # it_behaves_like 'NG' # NOTE: 未ログインの為、対象がない
      # it_behaves_like 'ToNG', 422, 'error', false
      it_behaves_like 'ToNG', 401, nil, false
      # it_behaves_like 'ToMsg', Array, 1, 'errors.messages.validate_account_update_params', nil, nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise.failure.unauthenticated', nil
    end
    shared_examples_for '[APIログイン中/削除予約済み]パラメータなし' do
      let(:params) { nil }
      it_behaves_like 'NG'
      # it_behaves_like 'ToNG', 422, 'error', false
      it_behaves_like 'ToNG', 400, nil, false
      # it_behaves_like 'ToMsg', Array, 1, 'errors.messages.validate_account_update_params', nil, nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'errors.messages.validate_account_update_params', nil
    end
    shared_examples_for '[APIログイン中]有効なパラメータ（変更なし）' do
      let(:params) { nochange_attributes.merge(password_confirmation: nochange_attributes[:password], current_password: user.password) }
      it_behaves_like 'OK', false
      # it_behaves_like 'ToOK', 'success', nil, true
      it_behaves_like 'ToOK', nil, true, false
      # it_behaves_like 'ToMsg', NilClass, 0, nil, nil, nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, nil, 'devise.registrations.updated'
    end
    shared_examples_for '[削除予約済み]有効なパラメータ（変更なし）' do
      let(:params) { nochange_attributes.merge(password_confirmation: nochange_attributes[:password], current_password: user.password) }
      # it_behaves_like 'OK', false
      it_behaves_like 'NG'
      # it_behaves_like 'ToOK', 'success', nil, true
      it_behaves_like 'ToNG', 422, nil, false
      # it_behaves_like 'ToMsg', NilClass, 0, nil, nil, nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'alert.user.destroy_reserved', nil
    end
    shared_examples_for '[未ログイン/ログイン中]有効なパラメータ（変更あり）' do
      let(:params) { valid_attributes.merge(password_confirmation: valid_attributes[:password]) }
      # it_behaves_like 'NG' # NOTE: 未ログインの為、対象がない
      # it_behaves_like 'ToNG', 404, 'error', false
      it_behaves_like 'ToNG', 401, nil, false
      # it_behaves_like 'ToMsg', Array, 1, 'devise_token_auth.registrations.user_not_found', nil, nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise.failure.unauthenticated', nil
    end
    shared_examples_for '[APIログイン中]有効なパラメータ（変更あり）' do
      let(:params) { valid_attributes.merge(password_confirmation: valid_attributes[:password], current_password: user.password) }
      it_behaves_like 'OK', true
      # it_behaves_like 'ToOK', 'success', nil, true
      it_behaves_like 'ToOK', nil, true, false
      # it_behaves_like 'ToMsg', NilClass, 0, nil, nil, nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, nil, 'devise.registrations.update_needs_confirmation'
    end
    shared_examples_for '[削除予約済み]有効なパラメータ（変更あり）' do
      let(:params) { valid_attributes.merge(password_confirmation: valid_attributes[:password], current_password: user.password) }
      # it_behaves_like 'OK', true
      it_behaves_like 'NG'
      # it_behaves_like 'ToOK', 'success', nil, true
      it_behaves_like 'ToNG', 422, nil, false
      # it_behaves_like 'ToMsg', NilClass, 0, nil, nil, nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'alert.user.destroy_reserved', nil
    end
    shared_examples_for '[未ログイン/ログイン中]無効なパラメータ' do
      let(:params) { invalid_attributes.merge(password_confirmation: invalid_attributes[:password]) }
      # it_behaves_like 'NG' # NOTE: 未ログインの為、対象がない
      # it_behaves_like 'ToNG', 404, 'error', false
      it_behaves_like 'ToNG', 401, nil, false
      # it_behaves_like 'ToMsg', Array, 1, 'devise_token_auth.registrations.user_not_found', nil, nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise.failure.unauthenticated', nil
    end
    shared_examples_for '[APIログイン中]無効なパラメータ' do
      let(:params) { invalid_attributes.merge(password_confirmation: invalid_attributes[:password], current_password: user.password) }
      # it_behaves_like 'OK', true
      it_behaves_like 'NG'
      # it_behaves_like 'ToOK', 'success', nil, true
      it_behaves_like 'ToNG', 422, nil, false
      # it_behaves_like 'ToMsg', NilClass, 0, nil, nil, nil, nil
      it_behaves_like 'ToMsg', Hash, 2, 'activerecord.errors.models.user.attributes.email.taken', nil, 'errors.messages.not_saved.one', nil
    end
    shared_examples_for '[削除予約済み]無効なパラメータ' do
      let(:params) { invalid_attributes.merge(password_confirmation: invalid_attributes[:password], current_password: user.password) }
      # it_behaves_like 'OK', true
      it_behaves_like 'NG'
      # it_behaves_like 'ToOK', 'success', nil, true
      it_behaves_like 'ToNG', 422, nil, false
      # it_behaves_like 'ToMsg', NilClass, 0, nil, nil, nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'alert.user.destroy_reserved', nil
    end
    shared_examples_for '[APIログイン中]現在のパスワードがない' do
      let(:params) { valid_attributes.merge(password_confirmation: valid_attributes[:password], current_password: nil) }
      it_behaves_like 'NG'
      # it_behaves_like 'ToNG', 422, 'error', nil
      it_behaves_like 'ToNG', 422, nil, false
      # it_behaves_like 'ToMsg', Hash, 2, 'activerecord.errors.models.user.attributes.current_password.blank', nil, nil, nil
      it_behaves_like 'ToMsg', Hash, 2, 'activerecord.errors.models.user.attributes.current_password.blank', nil, 'errors.messages.not_saved.one', nil
    end
    shared_examples_for '[削除予約済み]現在のパスワードがない' do
      let(:params) { valid_attributes.merge(password_confirmation: valid_attributes[:password], current_password: nil) }
      it_behaves_like 'NG'
      it_behaves_like 'ToNG', 422, nil, false
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'alert.user.destroy_reserved', nil
    end
    shared_examples_for '[未ログイン/ログイン中]URLがない' do
      let(:params) { invalid_attributes_nil.merge(password_confirmation: invalid_attributes_nil[:password]) }
      # it_behaves_like 'NG' # NOTE: 未ログインの為、対象がない
      # it_behaves_like 'ToNG', 404, 'error', false
      it_behaves_like 'ToNG', 401, nil, false
      # it_behaves_like 'ToMsg', Array, 1, 'devise_token_auth.registrations.user_not_found', nil, nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise.failure.unauthenticated', nil
    end
    shared_examples_for '[APIログイン中]URLがない' do
      let(:params) { invalid_attributes_nil.merge(password_confirmation: invalid_attributes_nil[:password], current_password: user.password) }
      # it_behaves_like 'OK', true
      it_behaves_like 'NG'
      # it_behaves_like 'ToOK', 'success', nil, true
      it_behaves_like 'ToNG', 422, nil, false
      # it_behaves_like 'ToMsg', NilClass, 0, nil, nil, nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise_token_auth.registrations.confirm_redirect_url_blank', nil
    end
    shared_examples_for '[削除予約済み]URLがない' do
      let(:params) { invalid_attributes_nil.merge(password_confirmation: invalid_attributes_nil[:password], current_password: user.password) }
      # it_behaves_like 'OK', true
      it_behaves_like 'NG'
      # it_behaves_like 'ToOK', 'success', nil, true
      it_behaves_like 'ToNG', 422, nil, false
      # it_behaves_like 'ToMsg', NilClass, 0, nil, nil, nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'alert.user.destroy_reserved', nil
    end
    shared_examples_for '[未ログイン/ログイン中]URLがホワイトリストにない' do
      let(:params) { invalid_attributes_bad.merge(password_confirmation: invalid_attributes_bad[:password]) }
      # it_behaves_like 'NG' # NOTE: 未ログインの為、対象がない
      # it_behaves_like 'ToNG', 404, 'error', false
      it_behaves_like 'ToNG', 401, nil, false
      # it_behaves_like 'ToMsg', Array, 1, 'devise_token_auth.registrations.user_not_found', nil, nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise.failure.unauthenticated', nil
    end
    shared_examples_for '[APIログイン中]URLがホワイトリストにない' do
      let(:params) { invalid_attributes_bad.merge(password_confirmation: invalid_attributes_bad[:password], current_password: user.password) }
      # it_behaves_like 'OK', true
      it_behaves_like 'NG'
      # it_behaves_like 'ToOK', 'success', nil, true
      it_behaves_like 'ToNG', 422, nil, false
      # it_behaves_like 'ToMsg', NilClass, 0, nil, nil, nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise_token_auth.registrations.confirm_redirect_url_not_allowed', nil
    end
    shared_examples_for '[削除予約済み]URLがホワイトリストにない' do
      let(:params) { invalid_attributes_bad.merge(password_confirmation: invalid_attributes_bad[:password], current_password: user.password) }
      # it_behaves_like 'OK', true
      it_behaves_like 'NG'
      # it_behaves_like 'ToOK', 'success', nil, true
      it_behaves_like 'ToNG', 422, nil, false
      # it_behaves_like 'ToMsg', NilClass, 0, nil, nil, nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'alert.user.destroy_reserved', nil
    end

    shared_examples_for '[未ログイン/ログイン中]' do
      it_behaves_like '[未ログイン/ログイン中]パラメータなし'
      # it_behaves_like '[未ログイン/ログイン中]有効なパラメータ（変更なし）' # NOTE: 未ログインの為、対象がない
      it_behaves_like '[未ログイン/ログイン中]有効なパラメータ（変更あり）'
      it_behaves_like '[未ログイン/ログイン中]無効なパラメータ'
      # it_behaves_like '[未ログイン/ログイン中]現在のパスワードがない' # NOTE: 未ログインの為、対象がない
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
      include_context 'APIログイン処理', nil, true
      it_behaves_like '[APIログイン中/削除予約済み]パラメータなし'
      it_behaves_like '[APIログイン中]有効なパラメータ（変更なし）'
      it_behaves_like '[APIログイン中]有効なパラメータ（変更あり）'
      it_behaves_like '[APIログイン中]無効なパラメータ'
      it_behaves_like '[APIログイン中]現在のパスワードがない'
      it_behaves_like '[APIログイン中]URLがない'
      it_behaves_like '[APIログイン中]URLがホワイトリストにない'
    end
    context 'APIログイン中（削除予約済み）' do
      include_context 'APIログイン処理', :destroy_reserved, true
      it_behaves_like '[APIログイン中/削除予約済み]パラメータなし'
      it_behaves_like '[削除予約済み]有効なパラメータ（変更なし）'
      it_behaves_like '[削除予約済み]有効なパラメータ（変更あり）'
      it_behaves_like '[削除予約済み]無効なパラメータ'
      it_behaves_like '[削除予約済み]現在のパスワードがない'
      it_behaves_like '[削除予約済み]URLがない'
      it_behaves_like '[削除予約済み]URLがホワイトリストにない'
    end
  end

  # POST /users/auth/image/update(.json) ユーザー画像変更API(処理)
  # テストパターン
  #   未ログイン, ログイン中, APIログイン中, APIログイン中（削除予約済み）
  #   有効なパラメータ, 無効なパラメータ
  #   ＋URLの拡張子: .json, ない
  #   ＋Acceptヘッダ: JSONが含まれる, JSONが含まれない
  describe 'POST #image_update' do
    subject { post update_user_auth_image_registration_path(format: subject_format), params:, headers: auth_headers.merge(accept_headers) }
    let(:valid_attributes)   { { image: fixture_file_upload(TEST_IMAGE_FILE, TEST_IMAGE_TYPE) } }
    let(:invalid_attributes) { nil }

    # テスト内容
    let(:current_user) { User.find(user.id) }
    include_context 'Authテスト内容'

    shared_examples_for 'OK' do
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      it '画像が変更される' do
        subject
        expect(current_user.image.url).not_to eq(user.image.url)
      end
    end
    shared_examples_for 'NG' do
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      it '画像が変更されない' do
        subject
        expect(current_user.image.url).to eq(user.image.url)
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
    shared_examples_for 'ToNG(json/json)' do |code|
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      it "HTTPステータスが#{code}。対象項目が一致する。認証ヘッダがない" do
        is_expected.to eq(code) # 方針(優先順): 401: 未ログイン, 400:パラメータなし, 422: 無効なパラメータ・状態
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
    shared_examples_for '[未ログイン/ログイン中]有効なパラメータ' do
      let(:params) { valid_attributes }
      # it_behaves_like 'NG' # NOTE: 未ログインの為、対象がない
      it_behaves_like 'ToNG', 401
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise.failure.unauthenticated', nil
    end
    shared_examples_for '[APIログイン中]有効なパラメータ' do
      let(:params) { valid_attributes }
      it_behaves_like 'OK'
      it_behaves_like 'ToOK'
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, nil, 'notice.user.image_update'
    end
    shared_examples_for '[削除予約済み]有効なパラメータ' do
      let(:params) { valid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToNG', 422
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'alert.user.destroy_reserved', nil
    end
    shared_examples_for '[未ログイン/ログイン中]無効なパラメータ' do
      let(:params) { invalid_attributes }
      # it_behaves_like 'NG' # NOTE: 未ログインの為、対象がない
      it_behaves_like 'ToNG', 401
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise.failure.unauthenticated', nil
    end
    shared_examples_for '[APIログイン中]無効なパラメータ' do
      let(:params) { invalid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToNG', 422
      it_behaves_like 'ToMsg', Hash, 2, 'activerecord.errors.models.user.attributes.image.blank', nil, 'errors.messages.not_saved.one', nil
    end
    shared_examples_for '[削除予約済み]無効なパラメータ' do
      let(:params) { invalid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToNG', 422
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'alert.user.destroy_reserved', nil
    end

    context '未ログイン' do
      include_context '未ログイン処理'
      it_behaves_like '[未ログイン/ログイン中]有効なパラメータ'
      it_behaves_like '[未ログイン/ログイン中]無効なパラメータ'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[未ログイン/ログイン中]有効なパラメータ'
      it_behaves_like '[未ログイン/ログイン中]無効なパラメータ'
    end
    context 'APIログイン中' do
      include_context 'APIログイン処理'
      it_behaves_like '[APIログイン中]有効なパラメータ'
      it_behaves_like '[APIログイン中]無効なパラメータ'
    end
    context 'APIログイン中（削除予約済み）' do
      include_context 'APIログイン処理', :destroy_reserved
      it_behaves_like '[削除予約済み]有効なパラメータ'
      it_behaves_like '[削除予約済み]無効なパラメータ'
    end
  end

  # POST /users/auth/image/delete(.json) ユーザー画像削除API(処理)
  # テストパターン
  #   未ログイン, ログイン中, APIログイン中, APIログイン中（削除予約済み）
  #   ＋URLの拡張子: .json, ない
  #   ＋Acceptヘッダ: JSONが含まれる, JSONが含まれない
  describe 'POST #image_destroy' do
    subject { post delete_user_auth_image_registration_path(format: subject_format), headers: auth_headers.merge(accept_headers) }

    # テスト内容
    let(:current_user) { User.find(user.id) }
    include_context 'Authテスト内容'

    shared_examples_for 'OK' do
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      it '画像が削除される' do
        subject
        expect(current_user.image.url).to be_nil
      end
    end
    shared_examples_for 'NG' do
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      it '画像が変更されない' do
        subject
        expect(current_user.image.url).to eq(user.image.url)
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
    shared_examples_for 'ToNG(json/json)' do |code|
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      it "HTTPステータスが#{code}。対象項目が一致する。認証ヘッダがない" do
        is_expected.to eq(code) # 方針(優先順): 401: 未ログイン, 400:パラメータなし, 422: 無効なパラメータ・状態
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
    context '未ログイン' do
      include_context '未ログイン処理'
      # it_behaves_like 'NG' # NOTE: 未ログインの為、対象がない
      it_behaves_like 'ToNG', 401
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise.failure.unauthenticated', nil
    end
    context 'ログイン中' do
      include_context 'ログイン処理', nil, true
      it_behaves_like 'NG'
      it_behaves_like 'ToNG', 401
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise.failure.unauthenticated', nil
    end
    context 'APIログイン中' do
      include_context 'APIログイン処理', nil, true
      it_behaves_like 'OK'
      it_behaves_like 'ToOK'
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, nil, 'notice.user.image_destroy'
    end
    context 'APIログイン中（削除予約済み）' do
      include_context 'APIログイン処理', :destroy_reserved, true
      it_behaves_like 'NG'
      it_behaves_like 'ToNG', 422
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'alert.user.destroy_reserved', nil
    end
  end

  # POST /users/auth/delete(.json) アカウント削除API(処理)
  # テストパターン
  #   未ログイン, ログイン中, APIログイン中, APIログイン中（削除予約済み）
  #   パラメータなし, 有効なパラメータ, URLがない, URLがホワイトリストにない
  #   ＋URLの拡張子: .json, ない
  #   ＋Acceptヘッダ: JSONが含まれる, JSONが含まれない
  describe 'POST #destroy' do
    subject { post destroy_user_auth_registration_path(format: subject_format), params:, headers: auth_headers.merge(accept_headers) }
    let(:valid_attributes)       { { undo_delete_url: FRONT_SITE_URL } }
    let(:invalid_attributes_nil) { { undo_delete_url: nil } }
    let(:invalid_attributes_bad) { { undo_delete_url: BAD_SITE_URL } }

    # テスト内容
    let(:current_user) { User.find(user.id) }
    include_context 'Authテスト内容'

    shared_examples_for 'OK' do
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      # it '削除される' do
      #   expect { subject }.to change(User, :count).by(-1)
      # end
      let!(:start_time) { Time.current.floor }
      it "削除依頼日時が現在日時に、削除予定日時が#{Settings.user_destroy_schedule_days}日後に変更される。メールが送信される" do
        subject
        expect(current_user.destroy_requested_at).to be_between(start_time, Time.current)
        expect(current_user.destroy_schedule_at).to be_between(start_time + Settings.user_destroy_schedule_days.days,
                                                               Time.current + Settings.user_destroy_schedule_days.days)
        expect(ActionMailer::Base.deliveries.count).to eq(1)
        expect(ActionMailer::Base.deliveries[0].subject).to eq(get_subject('mailer.user.destroy_reserved.subject')) # アカウント削除受け付けのお知らせ
        expect(ActionMailer::Base.deliveries[0].html_part.body).to include(params[:undo_delete_url])
        expect(ActionMailer::Base.deliveries[0].text_part.body).to include(params[:undo_delete_url])
      end
    end
    shared_examples_for 'NG' do
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      # it '削除されない' do
      #   expect { subject }.to change(User, :count).by(0)
      # end
      it '削除依頼日時・削除予定日時が変更されない。メールが送信されない' do
        subject
        expect(current_user.destroy_requested_at).to eq(user.destroy_requested_at)
        expect(current_user.destroy_schedule_at).to eq(user.destroy_schedule_at)
        expect(ActionMailer::Base.deliveries.count).to eq(0)
      end
    end

    shared_examples_for 'ToOK(json/json)' do # |status, success|
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      it 'HTTPステータスが200。対象項目が一致する。認証ヘッダがない' do
        is_expected.to eq(200)
        # expect(response_json['status']).to eq(status) # 方針: 廃止して、successに統一
        # expect(response_json['success']).to eq(success)
        # expect(response_json['data']).to be_nil
        expect_success_json
        expect_not_exist_auth_header
      end
    end
    shared_examples_for 'ToNG(json/json)' do |code| # , status, success|
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      it "HTTPステータスが#{code}。対象項目が一致する。認証ヘッダがない" do
        is_expected.to eq(code) # 方針(優先順): 401: 未ログイン, 422: 無効なパラメータ・状態
        # expect(response_json['status']).to eq(status) # 方針: 廃止して、successに統一
        # expect(response_json['success']).to eq(success)
        # expect(response_json['data']).to be_nil
        expect_failure_json
        expect_not_exist_auth_header
      end
    end

    shared_examples_for 'ToOK' do # |status, success|
      it_behaves_like 'ToNG(html/html)', 406
      it_behaves_like 'ToNG(html/json)', 406
      it_behaves_like 'ToNG(json/html)', 406
      it_behaves_like 'ToOK(json/json)' # , status, success
    end
    shared_examples_for 'ToNG' do |code| # , status, success|
      it_behaves_like 'ToNG(html/html)', 406
      it_behaves_like 'ToNG(html/json)', 406
      it_behaves_like 'ToNG(json/html)', 406
      it_behaves_like 'ToNG(json/json)', code # , status, success
    end

    # テストケース
    shared_examples_for '[未ログイン/ログイン中]パラメータなし' do
      let(:params) { nil }
      # it_behaves_like 'NG' # NOTE: 未ログインの為、対象がない
      # it_behaves_like 'ToNG', 404, 'error', false
      it_behaves_like 'ToNG', 401, nil, false
      # it_behaves_like 'ToMsg', NilClass, 0, 'devise_token_auth.registrations.account_to_destroy_not_found', nil, nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise.failure.unauthenticated', nil
    end
    shared_examples_for '[未ログイン/ログイン中]有効なパラメータ' do
      let(:params) { valid_attributes }
      # it_behaves_like 'NG' # NOTE: 未ログインの為、対象がない
      # it_behaves_like 'ToNG', 404, 'error', false
      it_behaves_like 'ToNG', 401, nil, false
      # it_behaves_like 'ToMsg', NilClass, 0, 'devise_token_auth.registrations.account_to_destroy_not_found', nil, nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise.failure.unauthenticated', nil
    end
    shared_examples_for '[未ログイン/ログイン中]URLがない' do
      let(:params) { invalid_attributes_nil }
      # it_behaves_like 'NG' # NOTE: 未ログインの為、対象がない
      # it_behaves_like 'ToNG', 404, 'error', false
      it_behaves_like 'ToNG', 401, nil, false
      # it_behaves_like 'ToMsg', NilClass, 0, 'devise_token_auth.registrations.account_to_destroy_not_found', nil, nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise.failure.unauthenticated', nil
    end
    shared_examples_for '[未ログイン/ログイン中]URLがホワイトリストにない' do
      let(:params) { invalid_attributes_bad }
      # it_behaves_like 'NG' # NOTE: 未ログインの為、対象がない
      # it_behaves_like 'ToNG', 404, 'error', false
      it_behaves_like 'ToNG', 401, nil, false
      # it_behaves_like 'ToMsg', NilClass, 0, 'devise_token_auth.registrations.account_to_destroy_not_found', nil, nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise.failure.unauthenticated', nil
    end
    shared_examples_for '[APIログイン中]パラメータなし' do
      let(:params) { nil }
      # it_behaves_like 'OK'
      it_behaves_like 'NG'
      # it_behaves_like 'ToOK', 'success', nil
      it_behaves_like 'ToNG', 400
      # it_behaves_like 'ToMsg', NilClass, 0, nil, 'devise_token_auth.registrations.account_with_uid_destroyed', nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'alert.user.destroy.params_blank', nil
    end
    shared_examples_for '[APIログイン中]有効なパラメータ' do
      let(:params) { valid_attributes }
      it_behaves_like 'OK'
      # it_behaves_like 'ToOK', 'success', nil
      it_behaves_like 'ToOK', nil, true
      # it_behaves_like 'ToMsg', NilClass, 0, nil, 'devise_token_auth.registrations.account_with_uid_destroyed', nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, nil, 'devise.registrations.destroy_reserved'
    end
    shared_examples_for '[APIログイン中]URLがない' do
      let(:params) { invalid_attributes_nil }
      # it_behaves_like 'OK'
      it_behaves_like 'NG'
      # it_behaves_like 'ToOK', 'success', nil
      it_behaves_like 'ToNG', 422
      # it_behaves_like 'ToMsg', NilClass, 0, nil, 'devise_token_auth.registrations.account_with_uid_destroyed', nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'alert.user.destroy.undo_delete_url_blank', nil
    end
    shared_examples_for '[APIログイン中]URLがホワイトリストにない' do
      let(:params) { invalid_attributes_bad }
      # it_behaves_like 'OK'
      it_behaves_like 'NG'
      # it_behaves_like 'ToOK', 'success', nil
      it_behaves_like 'ToNG', 422
      # it_behaves_like 'ToMsg', NilClass, 0, nil, 'devise_token_auth.registrations.account_with_uid_destroyed', nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'alert.user.destroy.undo_delete_url_not_allowed', nil
    end
    shared_examples_for '[削除予約済み]パラメータなし' do
      let(:params) { nil }
      # it_behaves_like 'OK'
      it_behaves_like 'NG'
      # it_behaves_like 'ToOK', 'success', nil
      it_behaves_like 'ToNG', 422, nil, false
      # it_behaves_like 'ToMsg', NilClass, 0, nil, 'devise_token_auth.registrations.account_with_uid_destroyed', nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'alert.user.destroy_reserved', nil
    end
    shared_examples_for '[削除予約済み]有効なパラメータ' do
      let(:params) { valid_attributes }
      # it_behaves_like 'OK'
      it_behaves_like 'NG'
      # it_behaves_like 'ToOK', 'success', nil
      it_behaves_like 'ToNG', 422, nil, false
      # it_behaves_like 'ToMsg', NilClass, 0, nil, 'devise_token_auth.registrations.account_with_uid_destroyed', nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'alert.user.destroy_reserved', nil
    end
    shared_examples_for '[削除予約済み]URLがない' do
      let(:params) { invalid_attributes_nil }
      # it_behaves_like 'OK'
      it_behaves_like 'NG'
      # it_behaves_like 'ToOK', 'success', nil
      it_behaves_like 'ToNG', 422, nil, false
      # it_behaves_like 'ToMsg', NilClass, 0, nil, 'devise_token_auth.registrations.account_with_uid_destroyed', nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'alert.user.destroy_reserved', nil
    end
    shared_examples_for '[削除予約済み]URLがホワイトリストにない' do
      let(:params) { invalid_attributes_bad }
      # it_behaves_like 'OK'
      it_behaves_like 'NG'
      # it_behaves_like 'ToOK', 'success', nil
      it_behaves_like 'ToNG', 422, nil, false
      # it_behaves_like 'ToMsg', NilClass, 0, nil, 'devise_token_auth.registrations.account_with_uid_destroyed', nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'alert.user.destroy_reserved', nil
    end

    shared_examples_for '[未ログイン/ログイン中]' do
      it_behaves_like '[未ログイン/ログイン中]パラメータなし'
      it_behaves_like '[未ログイン/ログイン中]有効なパラメータ'
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
      it_behaves_like '[APIログイン中]有効なパラメータ'
      it_behaves_like '[APIログイン中]URLがない'
      it_behaves_like '[APIログイン中]URLがホワイトリストにない'
    end
    context 'APIログイン中（削除予約済み）' do
      include_context 'APIログイン処理', :destroy_reserved
      it_behaves_like '[削除予約済み]パラメータなし'
      it_behaves_like '[削除予約済み]有効なパラメータ'
      it_behaves_like '[削除予約済み]URLがない'
      it_behaves_like '[削除予約済み]URLがホワイトリストにない'
    end
  end

  # POST /users/auth/undo_delete(.json) アカウント削除取り消しAPI(処理)
  # テストパターン
  #   未ログイン, ログイン中, APIログイン中, APIログイン中（削除予約済み）
  #   ＋URLの拡張子: .json, ない
  #   ＋Acceptヘッダ: JSONが含まれる, JSONが含まれない
  describe 'POST #undo_destroy' do
    subject { post undo_destroy_user_auth_registration_path(format: subject_format), headers: auth_headers.merge(accept_headers) }

    # テスト内容
    let(:current_user) { User.find(user.id) }
    include_context 'Authテスト内容'

    shared_examples_for 'OK' do
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      it '削除依頼日時・削除予定日時がなしに変更される。メールが送信される' do
        subject
        expect(current_user.destroy_requested_at).to be_nil
        expect(current_user.destroy_schedule_at).to be_nil
        expect(ActionMailer::Base.deliveries.count).to eq(1)
        expect(ActionMailer::Base.deliveries[0].subject).to eq(get_subject('mailer.user.undo_destroy_reserved.subject')) # アカウント削除取り消し完了のお知らせ
      end
    end
    shared_examples_for 'NG' do
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      it '削除依頼日時・削除予定日時が変更されない。メールが送信されない' do
        subject
        expect(current_user.destroy_requested_at).to eq(user.destroy_requested_at)
        expect(current_user.destroy_schedule_at).to eq(user.destroy_schedule_at)
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
    shared_examples_for 'ToNG(json/json)' do |code|
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      it "HTTPステータスが#{code}。対象項目が一致する。認証ヘッダがない" do
        is_expected.to eq(code) # 方針(優先順): 401: 未ログイン, 400:パラメータなし, 422: 無効なパラメータ・状態
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
    context '未ログイン' do
      include_context '未ログイン処理'
      # it_behaves_like 'NG' # NOTE: 未ログインの為、対象がない
      it_behaves_like 'ToNG', 401
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise.failure.unauthenticated', nil
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like 'NG'
      it_behaves_like 'ToNG', 401
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise.failure.unauthenticated', nil
    end
    context 'APIログイン中' do
      include_context 'APIログイン処理'
      it_behaves_like 'NG'
      it_behaves_like 'ToNG', 422
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'alert.user.not_destroy_reserved', nil
    end
    context 'APIログイン中（削除予約済み）' do
      include_context 'APIログイン処理', :destroy_reserved
      it_behaves_like 'OK'
      it_behaves_like 'ToOK'
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, nil, 'devise.registrations.undo_destroy_reserved'
    end
  end
end
