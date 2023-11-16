require 'rails_helper'

RSpec.describe 'Users::Auth::Sessions', type: :request do
  let(:response_json) { JSON.parse(response.body) }

  # テスト内容（共通）
  shared_examples_for 'ToMsg' do |error_msg, alert, notice|
    let(:subject_format) { :json }
    let(:accept_headers) { ACCEPT_INC_JSON }
    it '対象のメッセージと一致する' do
      subject
      # :nocov:
      expect(response_json['errors'].to_s).to error_msg.present? ? include(get_locale(error_msg)) : be_blank # 方針: 廃止して、alertへ
      expect(response_json['alert']).to alert.present? ? eq(get_locale(alert)) : be_nil # 方針: 追加
      expect(response_json['notice']).to notice.present? ? eq(get_locale(notice)) : be_nil # 方針: 追加
      # :nocov:
    end
  end

  # POST /users/auth/sign_in(.json) ログインAPI(処理)
  # テストパターン
  #   未ログイン, ログイン中, APIログイン中, APIログイン中（削除予約済み）
  #   パラメータなし, 有効なパラメータ（未ロック, ロック中, メール未確認, メールアドレス変更中, 削除予約済み）, 無効なパラメータ（存在しない, ロック前, ロック前の前, ロック前の前の前）, URLがない, URLがホワイトリストにない
  #   ＋URLの拡張子: .json, ない
  #   ＋Acceptヘッダ: JSONが含まれる, JSONが含まれない
  describe 'POST #create' do
    subject { post create_user_auth_session_path(format: subject_format), params:, headers: auth_headers.merge(accept_headers) }
    let_it_be(:send_user_unlocked)         { FactoryBot.create(:user) }
    let_it_be(:send_user_locked)           { FactoryBot.create(:user, :locked) }
    let_it_be(:send_user_unconfirmed)      { FactoryBot.create(:user, :unconfirmed) }
    let_it_be(:send_user_email_changed)    { FactoryBot.create(:user, :email_changed) }
    let_it_be(:send_user_destroy_reserved) { FactoryBot.create(:user, :destroy_reserved) }
    let_it_be(:not_user)                   { FactoryBot.attributes_for(:user) }
    let_it_be(:send_user_before_lock1)     { FactoryBot.create(:user, :before_lock1) }
    let_it_be(:send_user_before_lock2)     { FactoryBot.create(:user, :before_lock2) }
    let_it_be(:send_user_before_lock3)     { FactoryBot.create(:user, :before_lock3) }
    let(:valid_attributes)        { { email: send_user.email, password: send_user.password, unlock_redirect_url: FRONT_SITE_URL } }
    let(:invalid_attributes_not)  { { email: not_user[:email], password: not_user[:password], unlock_redirect_url: FRONT_SITE_URL } }
    let(:invalid_attributes_pass) { { email: send_user.email, password: "n#{send_user.password}", unlock_redirect_url: FRONT_SITE_URL } }
    let(:invalid_attributes_nil)  { { email: send_user.email, password: send_user.password, unlock_redirect_url: nil } }
    let(:invalid_attributes_bad)  { { email: send_user.email, password: send_user.password, unlock_redirect_url: BAD_SITE_URL } }

    # テスト内容
    let(:current_user) { User.find(send_user.id) }
    include_context 'Authテスト内容'

    shared_examples_for 'ToOK(json/json)' do # |success, id_present|
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      it 'HTTPステータスが200。対象項目が一致する。認証ヘッダがある' do
        is_expected.to eq(200)
        # expect(response_json['success']).to eq(success) # 方針: 成功時も返却
        # expect(response_json['data']['id'].present?).to eq(id_present) # 方針: 廃止
        # expect(response_json['data']['name']).to eq(send_user.name)
        # expect(response_json['data']['image']).not_to be_nil
        expect_success_json
        expect_exist_auth_header
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

    shared_examples_for 'ToOK' do # |success, id_present|
      it_behaves_like 'ToNG(html/html)', 406
      it_behaves_like 'ToNG(html/json)', 406
      it_behaves_like 'ToNG(json/html)', 406
      it_behaves_like 'ToOK(json/json)' # , success, id_present
    end
    shared_examples_for 'ToNG' do |code|
      it_behaves_like 'ToNG(html/html)', 406
      it_behaves_like 'ToNG(html/json)', 406
      it_behaves_like 'ToNG(json/html)', 406
      it_behaves_like 'ToNG(json/json)', code
    end

    shared_examples_for 'SendLocked' do
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      let(:url) { "http://#{Settings.base_domain}#{user_auth_unlock_path}" }
      let(:url_param) { "redirect_url=#{URI.encode_www_form_component(params[:unlock_redirect_url])}" }
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
    shared_examples_for 'NotSendLocked' do
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      it 'メールが送信されない' do
        expect { subject }.to change(ActionMailer::Base.deliveries, :count).by(0)
      end
    end

    # テストケース
    shared_examples_for '[未ログイン/ログイン中]パラメータなし' do
      let(:params) { nil }
      # it_behaves_like 'ToNG', 401
      it_behaves_like 'ToNG', 400
      # it_behaves_like 'ToMsg', 'devise_token_auth.sessions.bad_credentials', nil, nil
      it_behaves_like 'ToMsg', nil, 'devise_token_auth.sessions.bad_credentials', nil
      it_behaves_like 'NotSendLocked'
    end
    shared_examples_for '[APIログイン中/削除予約済み]パラメータなし' do
      let(:params) { nil }
      # it_behaves_like 'ToNG', 401 # NOTE: フロントと不一致で再ログイン出来なくなる為
      it_behaves_like 'ToNG', 400
      # it_behaves_like 'ToMsg', 'devise_token_auth.sessions.bad_credentials', nil, nil
      # it_behaves_like 'ToMsg', nil, 'devise.failure.already_authenticated', nil # NOTE: フロントと不一致で再ログイン出来なくなる為
      it_behaves_like 'ToMsg', nil, 'devise_token_auth.sessions.bad_credentials', nil
      it_behaves_like 'NotSendLocked'
    end
    shared_examples_for '[未ログイン/ログイン中]有効なパラメータ（未ロック）' do
      let(:send_user) { send_user_unlocked }
      let(:params) { valid_attributes }
      # it_behaves_like 'ToOK', nil, true
      it_behaves_like 'ToOK', true, false
      # it_behaves_like 'ToMsg', nil, nil, nil
      it_behaves_like 'ToMsg', nil, nil, 'devise.sessions.signed_in'
      it_behaves_like 'NotSendLocked'
    end
    shared_examples_for '[APIログイン中/削除予約済み]有効なパラメータ（未ロック）' do
      let(:send_user) { send_user_unlocked }
      let(:params) { valid_attributes }
      # it_behaves_like 'ToOK', nil, true
      # it_behaves_like 'ToNG', 401 # NOTE: フロントと不一致で再ログイン出来なくなる為
      it_behaves_like 'ToOK', true, false
      # it_behaves_like 'ToMsg', nil, nil, nil
      # it_behaves_like 'ToMsg', nil, 'devise.failure.already_authenticated', nil # NOTE: フロントと不一致で再ログイン出来なくなる為
      it_behaves_like 'ToMsg', nil, nil, 'devise.sessions.signed_in'
      it_behaves_like 'NotSendLocked'
    end
    shared_examples_for '[未ログイン/ログイン中]有効なパラメータ（ロック中）' do
      let(:send_user) { send_user_locked }
      let(:params) { valid_attributes }
      # it_behaves_like 'ToNG', 401
      it_behaves_like 'ToNG', 422
      # it_behaves_like 'ToMsg', 'devise.mailer.unlock_instructions.account_lock_msg', nil, nil
      it_behaves_like 'ToMsg', nil, 'devise.failure.locked', nil
      it_behaves_like 'NotSendLocked'
    end
    shared_examples_for '[APIログイン中/削除予約済み]有効なパラメータ（ロック中）' do
      let(:send_user) { send_user_locked }
      let(:params) { valid_attributes }
      # it_behaves_like 'ToNG', 401 # NOTE: フロントと不一致で再ログイン出来なくなる為
      it_behaves_like 'ToNG', 422
      # it_behaves_like 'ToMsg', 'devise.mailer.unlock_instructions.account_lock_msg', nil, nil
      # it_behaves_like 'ToMsg', nil, 'devise.failure.already_authenticated', nil # NOTE: フロントと不一致で再ログイン出来なくなる為
      it_behaves_like 'ToMsg', nil, 'devise.failure.locked', nil
      it_behaves_like 'NotSendLocked'
    end
    shared_examples_for '[未ログイン/ログイン中]有効なパラメータ（メール未確認）' do
      let(:send_user) { send_user_unconfirmed }
      let(:params) { valid_attributes }
      # it_behaves_like 'ToNG', 401
      it_behaves_like 'ToNG', 422
      # it_behaves_like 'ToMsg', 'devise.failure.unconfirmed', nil, nil
      it_behaves_like 'ToMsg', nil, 'devise.failure.unconfirmed', nil
      it_behaves_like 'NotSendLocked'
    end
    shared_examples_for '[APIログイン中/削除予約済み]有効なパラメータ（メール未確認）' do
      let(:send_user) { send_user_unconfirmed }
      let(:params) { valid_attributes }
      # it_behaves_like 'ToNG', 401 # NOTE: フロントと不一致で再ログイン出来なくなる為
      it_behaves_like 'ToNG', 422
      # it_behaves_like 'ToMsg', 'devise_token_auth.sessions.not_confirmed', nil, nil
      # it_behaves_like 'ToMsg', nil, 'devise.failure.already_authenticated', nil # NOTE: フロントと不一致で再ログイン出来なくなる為
      it_behaves_like 'ToMsg', nil, 'devise.failure.unconfirmed', nil
      it_behaves_like 'NotSendLocked'
    end
    shared_examples_for '[未ログイン/ログイン中]有効なパラメータ（メールアドレス変更中）' do
      let(:send_user) { send_user_email_changed }
      let(:params) { valid_attributes }
      # it_behaves_like 'ToOK', nil, true
      it_behaves_like 'ToOK', true, false
      # it_behaves_like 'ToMsg', nil, nil, nil
      it_behaves_like 'ToMsg', nil, nil, 'devise.sessions.signed_in'
      it_behaves_like 'NotSendLocked'
    end
    shared_examples_for '[APIログイン中/削除予約済み]有効なパラメータ（メールアドレス変更中）' do
      let(:send_user) { send_user_email_changed }
      let(:params) { valid_attributes }
      # it_behaves_like 'ToOK', nil, true
      # it_behaves_like 'ToNG', 401 # NOTE: フロントと不一致で再ログイン出来なくなる為
      it_behaves_like 'ToOK', true, false
      # it_behaves_like 'ToMsg', nil, nil, nil
      # it_behaves_like 'ToMsg', nil, 'devise.failure.already_authenticated', nil # NOTE: フロントと不一致で再ログイン出来なくなる為
      it_behaves_like 'ToMsg', nil, nil, 'devise.sessions.signed_in'
      it_behaves_like 'NotSendLocked'
    end
    shared_examples_for '[未ログイン/ログイン中]有効なパラメータ（削除予約済み）' do
      let(:send_user) { send_user_destroy_reserved }
      let(:params) { valid_attributes }
      # it_behaves_like 'ToOK', nil, true
      it_behaves_like 'ToOK', true, false
      # it_behaves_like 'ToMsg', nil, nil, nil
      it_behaves_like 'ToMsg', nil, nil, 'devise.sessions.signed_in'
      it_behaves_like 'NotSendLocked'
    end
    shared_examples_for '[APIログイン中/削除予約済み]有効なパラメータ（削除予約済み）' do
      let(:send_user) { send_user_destroy_reserved }
      let(:params) { valid_attributes }
      # it_behaves_like 'ToOK', nil, true
      # it_behaves_like 'ToNG', 401 # NOTE: フロントと不一致で再ログイン出来なくなる為
      it_behaves_like 'ToOK', true, false
      # it_behaves_like 'ToMsg', nil, nil, nil
      # it_behaves_like 'ToMsg', nil, 'devise.failure.already_authenticated', nil # NOTE: フロントと不一致で再ログイン出来なくなる為
      it_behaves_like 'ToMsg', nil, nil, 'devise.sessions.signed_in'
      it_behaves_like 'NotSendLocked'
    end
    shared_examples_for '[未ログイン/ログイン中]無効なパラメータ（存在しない）' do
      let(:params) { invalid_attributes_not }
      # it_behaves_like 'ToNG', 401
      it_behaves_like 'ToNG', 422
      # it_behaves_like 'ToMsg', 'devise_token_auth.sessions.bad_credentials', nil, nil
      it_behaves_like 'ToMsg', nil, 'devise.failure.invalid', nil
      it_behaves_like 'NotSendLocked'
    end
    shared_examples_for '[APIログイン中/削除予約済み]無効なパラメータ（存在しない）' do
      let(:params) { invalid_attributes_not }
      # it_behaves_like 'ToNG', 401 # NOTE: フロントと不一致で再ログイン出来なくなる為
      it_behaves_like 'ToNG', 422
      # it_behaves_like 'ToMsg', 'devise_token_auth.sessions.bad_credentials', nil, nil
      # it_behaves_like 'ToMsg', nil, 'devise.failure.already_authenticated', nil # NOTE: フロントと不一致で再ログイン出来なくなる為
      it_behaves_like 'ToMsg', nil, 'devise.failure.invalid', nil
      it_behaves_like 'NotSendLocked'
    end
    shared_examples_for '[*]無効なパラメータ（ロック前）' do
      let(:send_user) { send_user_before_lock1 }
      let(:params) { invalid_attributes_pass }
      it_behaves_like 'ToNG', 422
      it_behaves_like 'ToMsg', nil, 'devise.failure.send_locked', nil
      it_behaves_like 'SendLocked'
    end
    shared_examples_for '[*]無効なパラメータ（ロック前の前）' do
      let(:send_user) { send_user_before_lock2 }
      let(:params) { invalid_attributes_pass }
      it_behaves_like 'ToNG', 422
      it_behaves_like 'ToMsg', nil, 'devise.failure.last_attempt', nil
      it_behaves_like 'NotSendLocked'
    end
    shared_examples_for '[*]無効なパラメータ（ロック前の前の前）' do
      let(:send_user) { send_user_before_lock3 }
      let(:params) { invalid_attributes_pass }
      it_behaves_like 'ToNG', 422
      it_behaves_like 'ToMsg', nil, 'devise.failure.invalid', nil
      it_behaves_like 'NotSendLocked'
    end
    shared_examples_for '[*]URLがない' do
      let(:send_user) { send_user_unlocked }
      let(:params) { invalid_attributes_nil }
      it_behaves_like 'ToNG', 422
      it_behaves_like 'ToMsg', nil, 'devise_token_auth.sessions.unlock_redirect_url_blank', nil
      it_behaves_like 'NotSendLocked'
    end
    shared_examples_for '[*]URLがホワイトリストにない' do
      let(:send_user) { send_user_unlocked }
      let(:params) { invalid_attributes_bad }
      it_behaves_like 'ToNG', 422
      it_behaves_like 'ToMsg', nil, 'devise_token_auth.sessions.unlock_redirect_url_not_allowed', nil
      it_behaves_like 'NotSendLocked'
    end

    shared_examples_for '[未ログイン/ログイン中]' do
      it_behaves_like '[未ログイン/ログイン中]パラメータなし'
      it_behaves_like '[未ログイン/ログイン中]有効なパラメータ（未ロック）'
      it_behaves_like '[未ログイン/ログイン中]有効なパラメータ（ロック中）'
      it_behaves_like '[未ログイン/ログイン中]有効なパラメータ（メール未確認）'
      it_behaves_like '[未ログイン/ログイン中]有効なパラメータ（メールアドレス変更中）'
      it_behaves_like '[未ログイン/ログイン中]有効なパラメータ（削除予約済み）'
      it_behaves_like '[未ログイン/ログイン中]無効なパラメータ（存在しない）'
    end
    shared_examples_for '[APIログイン中/削除予約済み]' do
      it_behaves_like '[APIログイン中/削除予約済み]パラメータなし'
      it_behaves_like '[APIログイン中/削除予約済み]有効なパラメータ（未ロック）'
      it_behaves_like '[APIログイン中/削除予約済み]有効なパラメータ（ロック中）'
      it_behaves_like '[APIログイン中/削除予約済み]有効なパラメータ（メール未確認）'
      it_behaves_like '[APIログイン中/削除予約済み]有効なパラメータ（メールアドレス変更中）'
      it_behaves_like '[APIログイン中/削除予約済み]有効なパラメータ（削除予約済み）'
      it_behaves_like '[APIログイン中/削除予約済み]無効なパラメータ（存在しない）'
    end
    shared_examples_for '[*]' do
      it_behaves_like '[*]無効なパラメータ（ロック前）'
      it_behaves_like '[*]無効なパラメータ（ロック前の前）'
      it_behaves_like '[*]無効なパラメータ（ロック前の前の前）'
      it_behaves_like '[*]URLがない'
      it_behaves_like '[*]URLがホワイトリストにない'
    end

    context '未ログイン' do
      include_context '未ログイン処理'
      it_behaves_like '[未ログイン/ログイン中]'
      it_behaves_like '[*]'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[未ログイン/ログイン中]'
      it_behaves_like '[*]'
    end
    context 'APIログイン中' do
      include_context 'APIログイン処理'
      it_behaves_like '[APIログイン中/削除予約済み]'
      it_behaves_like '[*]'
    end
    context 'APIログイン中（削除予約済み）' do
      include_context 'APIログイン処理', :destroy_reserved
      it_behaves_like '[APIログイン中/削除予約済み]'
      it_behaves_like '[*]'
    end
  end

  # POST /users/auth/sign_out(.json) ログアウトAPI(処理)
  # テストパターン
  #   未ログイン, ログイン中, APIログイン中, APIログイン中（削除予約済み）
  #   ＋URLの拡張子: .json, ない
  #   ＋Acceptヘッダ: JSONが含まれる, JSONが含まれない
  describe 'POST #destroy' do
    subject { post destroy_user_auth_session_path(format: subject_format), headers: auth_headers.merge(accept_headers) }

    # テスト内容
    let(:current_user) { user }
    include_context 'Authテスト内容'

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
        is_expected.to eq(code) # 方針: 401: 未ログイン
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
    shared_examples_for '[未ログイン/ログイン中]' do
      # it_behaves_like 'ToNG', 404
      it_behaves_like 'ToNG', 401
      # it_behaves_like 'ToMsg', 'devise_token_auth.sessions.user_not_found', nil, nil
      it_behaves_like 'ToMsg', nil, 'devise_token_auth.sessions.user_not_found', nil
    end
    shared_examples_for '[APIログイン中/削除予約済み]' do
      it_behaves_like 'ToOK'
      # it_behaves_like 'ToMsg', nil, nil, nil
      it_behaves_like 'ToMsg', nil, nil, 'devise.sessions.signed_out'
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
      it_behaves_like '[APIログイン中/削除予約済み]'
    end
    context 'APIログイン中（削除予約済み）' do
      include_context 'APIログイン処理', :destroy_reserved
      it_behaves_like '[APIログイン中/削除予約済み]'
    end
  end
end
