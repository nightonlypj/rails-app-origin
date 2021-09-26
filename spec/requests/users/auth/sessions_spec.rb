require 'rails_helper'

RSpec.describe 'Users::Auth::Sessions', type: :request do
  # テスト内容（共通）
  shared_examples_for 'ToMsg' do |error_msg, alert, notice|
    it '対象のメッセージと一致する' do
      subject
      response_json = JSON.parse(response.body)
      expect(response_json['errors'].to_s).to error_msg.present? ? include(I18n.t(error_msg)) : be_blank # 方針: 廃止して、alertへ

      expect(response_json['alert']).to alert.present? ? eq(I18n.t(alert)) : be_nil # 方針: 追加
      expect(response_json['notice']).to notice.present? ? eq(I18n.t(notice)) : be_nil # 方針: 追加
    end
  end

  # POST /users/auth/sign_in(.json) ログインAPI(処理)
  # 前提条件
  #   Acceptヘッダがない
  # テストパターン
  #   URLの拡張子: ない, .json
  describe 'POST #create' do
    subject { post create_user_auth_session_path(format: subject_format) }

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
  #   未ログイン, ログイン中, APIログイン中, APIログイン中（削除予約済み）
  #   パラメータなし, 有効なパラメータ（未ロック, ロック中, メール未確認, メールアドレス変更中, 削除予約済み）, 無効なパラメータ
  describe 'POST #create(json)' do
    subject { post create_user_auth_session_path(format: subject_format), params: attributes, headers: auth_headers.merge(ACCEPT_JSON) }
    let(:send_user_unlocked)         { FactoryBot.create(:user) }
    let(:send_user_locked)           { FactoryBot.create(:user_locked) }
    let(:send_user_unconfirmed)      { FactoryBot.create(:user_unconfirmed) }
    let(:send_user_email_changed)    { FactoryBot.create(:user_email_changed) }
    let(:send_user_destroy_reserved) { FactoryBot.create(:user_destroy_reserved) }
    let(:not_user)                   { FactoryBot.attributes_for(:user) }
    let(:valid_attributes)   { { email: send_user.email, password: send_user.password } }
    let(:invalid_attributes) { { email: not_user[:email], password: not_user[:password] } }
    include_context 'Authテスト内容'
    let(:current_user) { User.find(send_user.id) }

    # テスト内容
    shared_examples_for 'ToOK' do # |success, id_present|
      it 'HTTPステータスが200。対象項目が一致する。認証ヘッダがある' do
        is_expected.to eq(200)
        # response_json = JSON.parse(response.body)
        # expect(response_json['success']).to eq(success) # 方針: 成功時も返却
        # expect(response_json['data']['id'].present?).to eq(id_present) # 方針: 廃止
        # expect(response_json['data']['name']).to eq(send_user.name)
        # expect(response_json['data']['image']).not_to be_nil
        expect_success_json
        expect_exist_auth_header
      end
    end
    shared_examples_for 'ToNG' do |code|
      it "HTTPステータスが#{code}。対象項目が一致する。認証ヘッダがない" do
        is_expected.to eq(code) # 方針(優先順): 401: ログイン中, 400:パラメータなし, 422: 無効なパラメータ・状態
        expect_failure_json
        expect_not_exist_auth_header
      end
    end

    # テストケース
    shared_examples_for '[未ログイン/ログイン中]パラメータなし' do
      let(:attributes) { nil }
      # it_behaves_like 'ToNG', 401
      it_behaves_like 'ToNG', 400
      # it_behaves_like 'ToMsg', 'devise_token_auth.sessions.bad_credentials', nil, nil
      it_behaves_like 'ToMsg', nil, 'devise_token_auth.sessions.bad_credentials', nil
    end
    shared_examples_for '[APIログイン中/削除予約済み]パラメータなし' do
      let(:attributes) { nil }
      # it_behaves_like 'ToNG', 401
      it_behaves_like 'ToNG', 401
      # it_behaves_like 'ToMsg', 'devise_token_auth.sessions.bad_credentials', nil, nil
      it_behaves_like 'ToMsg', nil, 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン/ログイン中]有効なパラメータ（未ロック）' do
      let(:send_user)  { send_user_unlocked }
      let(:attributes) { valid_attributes }
      # it_behaves_like 'ToOK', nil, true
      it_behaves_like 'ToOK', true, false
      # it_behaves_like 'ToMsg', nil, nil, nil
      it_behaves_like 'ToMsg', nil, nil, 'devise.sessions.signed_in'
    end
    shared_examples_for '[APIログイン中/削除予約済み]有効なパラメータ（未ロック）' do
      let(:send_user)  { send_user_unlocked }
      let(:attributes) { valid_attributes }
      # it_behaves_like 'ToOK', nil, true
      it_behaves_like 'ToNG', 401
      # it_behaves_like 'ToMsg', nil, nil, nil
      it_behaves_like 'ToMsg', nil, 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン/ログイン中]有効なパラメータ（ロック中）' do
      let(:send_user)  { send_user_locked }
      let(:attributes) { valid_attributes }
      # it_behaves_like 'ToNG', 401
      it_behaves_like 'ToNG', 422
      # it_behaves_like 'ToMsg', 'devise.mailer.unlock_instructions.account_lock_msg', nil, nil
      it_behaves_like 'ToMsg', nil, 'devise.failure.locked', nil
    end
    shared_examples_for '[APIログイン中/削除予約済み]有効なパラメータ（ロック中）' do
      let(:send_user)  { send_user_locked }
      let(:attributes) { valid_attributes }
      it_behaves_like 'ToNG', 401
      # it_behaves_like 'ToMsg', 'devise.mailer.unlock_instructions.account_lock_msg', nil, nil
      it_behaves_like 'ToMsg', nil, 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン/ログイン中]有効なパラメータ（メール未確認）' do
      let(:send_user)  { send_user_unconfirmed }
      let(:attributes) { valid_attributes }
      # it_behaves_like 'ToNG', 401
      it_behaves_like 'ToNG', 422
      # it_behaves_like 'ToMsg', 'devise.failure.unconfirmed', nil, nil
      it_behaves_like 'ToMsg', nil, 'devise.failure.unconfirmed', nil
    end
    shared_examples_for '[APIログイン中/削除予約済み]有効なパラメータ（メール未確認）' do
      let(:send_user)  { send_user_unconfirmed }
      let(:attributes) { valid_attributes }
      it_behaves_like 'ToNG', 401
      # it_behaves_like 'ToMsg', 'devise_token_auth.sessions.not_confirmed', nil, nil
      it_behaves_like 'ToMsg', nil, 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン/ログイン中]有効なパラメータ（メールアドレス変更中）' do
      let(:send_user)  { send_user_email_changed }
      let(:attributes) { valid_attributes }
      # it_behaves_like 'ToOK', nil, true
      it_behaves_like 'ToOK', true, false
      # it_behaves_like 'ToMsg', nil, nil, nil
      it_behaves_like 'ToMsg', nil, nil, 'devise.sessions.signed_in'
    end
    shared_examples_for '[APIログイン中/削除予約済み]有効なパラメータ（メールアドレス変更中）' do
      let(:send_user)  { send_user_email_changed }
      let(:attributes) { valid_attributes }
      # it_behaves_like 'ToOK', nil, true
      it_behaves_like 'ToNG', 401
      # it_behaves_like 'ToMsg', nil, nil, nil
      it_behaves_like 'ToMsg', nil, 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン/ログイン中]有効なパラメータ（削除予約済み）' do
      let(:send_user)  { send_user_destroy_reserved }
      let(:attributes) { valid_attributes }
      # it_behaves_like 'ToOK', nil, true
      it_behaves_like 'ToOK', true, false
      # it_behaves_like 'ToMsg', nil, nil, nil
      it_behaves_like 'ToMsg', nil, nil, 'devise.sessions.signed_in'
    end
    shared_examples_for '[APIログイン中/削除予約済み]有効なパラメータ（削除予約済み）' do
      let(:send_user)  { send_user_destroy_reserved }
      let(:attributes) { valid_attributes }
      # it_behaves_like 'ToOK', nil, true
      it_behaves_like 'ToNG', 401
      # it_behaves_like 'ToMsg', nil, nil, nil
      it_behaves_like 'ToMsg', nil, 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン/ログイン中]無効なパラメータ' do
      let(:send_user)  { send_user_unlocked }
      let(:attributes) { invalid_attributes }
      # it_behaves_like 'ToNG', 401
      it_behaves_like 'ToNG', 422
      # it_behaves_like 'ToMsg', 'devise_token_auth.sessions.bad_credentials', nil, nil
      it_behaves_like 'ToMsg', nil, 'devise.failure.invalid', nil
    end
    shared_examples_for '[APIログイン中/削除予約済み]無効なパラメータ' do
      let(:send_user)  { send_user_unlocked }
      let(:attributes) { invalid_attributes }
      it_behaves_like 'ToNG', 401
      # it_behaves_like 'ToMsg', 'devise_token_auth.sessions.bad_credentials', nil, nil
      it_behaves_like 'ToMsg', nil, 'devise.failure.already_authenticated', nil
    end

    shared_examples_for '未ログイン' do
      include_context '未ログイン処理'
      it_behaves_like '[未ログイン/ログイン中]パラメータなし'
      it_behaves_like '[未ログイン/ログイン中]有効なパラメータ（未ロック）'
      it_behaves_like '[未ログイン/ログイン中]有効なパラメータ（ロック中）'
      it_behaves_like '[未ログイン/ログイン中]有効なパラメータ（メール未確認）'
      it_behaves_like '[未ログイン/ログイン中]有効なパラメータ（メールアドレス変更中）'
      it_behaves_like '[未ログイン/ログイン中]有効なパラメータ（削除予約済み）'
      it_behaves_like '[未ログイン/ログイン中]無効なパラメータ'
    end
    shared_examples_for 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[未ログイン/ログイン中]パラメータなし'
      it_behaves_like '[未ログイン/ログイン中]有効なパラメータ（未ロック）'
      it_behaves_like '[未ログイン/ログイン中]有効なパラメータ（ロック中）'
      it_behaves_like '[未ログイン/ログイン中]有効なパラメータ（メール未確認）'
      it_behaves_like '[未ログイン/ログイン中]有効なパラメータ（メールアドレス変更中）'
      it_behaves_like '[未ログイン/ログイン中]有効なパラメータ（削除予約済み）'
      it_behaves_like '[未ログイン/ログイン中]無効なパラメータ'
    end
    shared_examples_for 'APIログイン中' do
      include_context 'APIログイン処理'
      it_behaves_like '[APIログイン中/削除予約済み]パラメータなし'
      it_behaves_like '[APIログイン中/削除予約済み]有効なパラメータ（未ロック）'
      it_behaves_like '[APIログイン中/削除予約済み]有効なパラメータ（ロック中）'
      it_behaves_like '[APIログイン中/削除予約済み]有効なパラメータ（メール未確認）'
      it_behaves_like '[APIログイン中/削除予約済み]有効なパラメータ（メールアドレス変更中）'
      it_behaves_like '[APIログイン中/削除予約済み]有効なパラメータ（削除予約済み）'
      it_behaves_like '[APIログイン中/削除予約済み]無効なパラメータ'
    end
    shared_examples_for 'APIログイン中（削除予約済み）' do
      include_context 'APIログイン処理', :user_destroy_reserved
      it_behaves_like '[APIログイン中/削除予約済み]パラメータなし'
      it_behaves_like '[APIログイン中/削除予約済み]有効なパラメータ（未ロック）'
      it_behaves_like '[APIログイン中/削除予約済み]有効なパラメータ（ロック中）'
      it_behaves_like '[APIログイン中/削除予約済み]有効なパラメータ（メール未確認）'
      it_behaves_like '[APIログイン中/削除予約済み]有効なパラメータ（メールアドレス変更中）'
      it_behaves_like '[APIログイン中/削除予約済み]有効なパラメータ（削除予約済み）'
      it_behaves_like '[APIログイン中/削除予約済み]無効なパラメータ'
    end

    context 'URLの拡張子がない' do
      let(:subject_format) { nil }
      it_behaves_like '未ログイン'
      it_behaves_like 'ログイン中'
      it_behaves_like 'APIログイン中'
      it_behaves_like 'APIログイン中（削除予約済み）'
    end
    context 'URLの拡張子が.json' do
      let(:subject_format) { :json }
      it_behaves_like '未ログイン'
      it_behaves_like 'ログイン中'
      it_behaves_like 'APIログイン中'
      it_behaves_like 'APIログイン中（削除予約済み）'
    end
  end

  # DELETE /users/auth/sign_out(.json) ログアウトAPI(処理)
  # 前提条件
  #   Acceptヘッダがない
  # テストパターン
  #   URLの拡張子: ない, .json
  describe 'DELETE #destroy' do
    subject { delete destroy_user_auth_session_path(format: subject_format) }

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
  #   未ログイン, ログイン中, APIログイン中, APIログイン中（削除予約済み）
  describe 'DELETE #destroy(json)' do
    subject { delete destroy_user_auth_session_path(format: subject_format), headers: auth_headers.merge(ACCEPT_JSON) }
    include_context 'Authテスト内容'
    let(:current_user) { user }

    # テスト内容
    shared_examples_for 'ToOK' do
      it 'HTTPステータスが200。対象項目が一致する。認証ヘッダがない' do
        is_expected.to eq(200)
        expect_success_json
        expect_not_exist_auth_header
      end
    end
    shared_examples_for 'ToNG' do |code|
      it "HTTPステータスが#{code}。対象項目が一致する。認証ヘッダがない" do
        is_expected.to eq(code) # 方針: 401: 未ログイン
        expect_failure_json
        expect_not_exist_auth_header
      end
    end

    # テストケース
    shared_examples_for '未ログイン' do
      include_context '未ログイン処理'
      # it_behaves_like 'ToNG', 404
      it_behaves_like 'ToNG', 401
      # it_behaves_like 'ToMsg', 'devise_token_auth.sessions.user_not_found', nil, nil
      it_behaves_like 'ToMsg', nil, 'devise_token_auth.sessions.user_not_found', nil
    end
    shared_examples_for 'ログイン中' do
      include_context 'ログイン処理'
      # it_behaves_like 'ToNG', 404
      it_behaves_like 'ToNG', 401
      # it_behaves_like 'ToMsg', 'devise_token_auth.sessions.user_not_found', nil, nil
      it_behaves_like 'ToMsg', nil, 'devise_token_auth.sessions.user_not_found', nil
    end
    shared_examples_for 'APIログイン中' do
      include_context 'APIログイン処理'
      it_behaves_like 'ToOK'
      # it_behaves_like 'ToMsg', nil, nil, nil
      it_behaves_like 'ToMsg', nil, nil, 'devise.sessions.signed_out'
    end
    shared_examples_for 'APIログイン中（削除予約済み）' do
      include_context 'APIログイン処理', :user_destroy_reserved
      it_behaves_like 'ToOK'
      # it_behaves_like 'ToMsg', nil, nil, nil
      it_behaves_like 'ToMsg', nil, nil, 'devise.sessions.signed_out'
    end

    context 'URLの拡張子がない' do
      let(:subject_format) { nil }
      it_behaves_like '未ログイン'
      it_behaves_like 'ログイン中'
      it_behaves_like 'APIログイン中'
      it_behaves_like 'APIログイン中（削除予約済み）'
    end
    context 'URLの拡張子が.json' do
      let(:subject_format) { :json }
      it_behaves_like '未ログイン'
      it_behaves_like 'ログイン中'
      it_behaves_like 'APIログイン中'
      it_behaves_like 'APIログイン中（削除予約済み）'
    end
  end
end
