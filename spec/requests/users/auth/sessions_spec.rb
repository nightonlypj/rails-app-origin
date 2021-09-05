require 'rails_helper'

RSpec.describe 'Users::Auth::Sessions', type: :request do
  # POST /users/auth/sign_in ログイン(処理)
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  #   パラメータなし, 有効なパラメータ（未ロック, ロック中, メール未確認, メールアドレス変更中, 削除予約済み）, 無効なパラメータ → 事前にデータ作成
  describe 'POST #create' do
    subject { post create_user_auth_session_path, params: attributes, headers: auth_headers }
    let(:send_user_unlocked)         { FactoryBot.create(:user) }
    let(:send_user_locked)           { FactoryBot.create(:user_locked) }
    let(:send_user_unconfirmed)      { FactoryBot.create(:user_unconfirmed) }
    let(:send_user_email_changed)    { FactoryBot.create(:user_email_changed) }
    let(:send_user_destroy_reserved) { FactoryBot.create(:user_destroy_reserved) }
    let(:not_user)                   { FactoryBot.attributes_for(:user) }
    let(:valid_attributes)   { { email: send_user.email, password: send_user.password } }
    let(:invalid_attributes) { { email: not_user[:email], password: not_user[:password] } }

    # テスト内容
    shared_examples_for 'ToOK' do |success, id_present|
      it '成功ステータス。対象項目が一致する。認証ヘッダがある' do
        is_expected.to eq(200)
        response_json = JSON.parse(response.body)
        expect(response_json['success']).to eq(success) # 方針: 成功時も返却

        expect(response_json['data']['id'].present?).to eq(id_present) # 方針: 廃止
        expect(response_json['data']['name']).to eq(send_user.name)

        expect(response.header['uid']).not_to be_nil
        expect(response.header['client']).not_to be_nil
        expect(response.header['access-token']).not_to be_nil
      end
    end
    shared_examples_for 'ToNG' do |code|
      it '失敗ステータス。対象項目が一致する。認証ヘッダがない' do
        is_expected.to eq(code) # 方針(優先順): 401: ログイン中, 400:パラメータなし, 422: 無効なパラメータ・状態
        response_json = JSON.parse(response.body)
        expect(response_json['success']).to eq(false)

        expect(response_json['data']).to be_nil

        expect(response.header['uid']).to be_nil
        expect(response.header['client']).to be_nil
        expect(response.header['access-token']).to be_nil
      end
    end
    shared_examples_for 'ToMsg' do |error_msg, alert, notice|
      it '対象のメッセージと一致する' do
        subject
        response_json = JSON.parse(response.body)
        expect(response_json['errors'].to_s).to error_msg.present? ? include(I18n.t(error_msg)) : be_blank # 方針: 廃止して、alertへ

        expect(response_json['alert']).to alert.present? ? eq(I18n.t(alert)) : be_nil # 方針: 追加
        expect(response_json['notice']).to notice.present? ? eq(I18n.t(notice)) : be_nil # 方針: 追加
      end
    end

    # テストケース
    shared_examples_for '[*]パラメータなし' do
      let(:attributes) { nil }
      it_behaves_like 'ToNG', 401
      # it_behaves_like 'ToNG', 400
      it_behaves_like 'ToMsg', 'devise_token_auth.sessions.bad_credentials', nil, nil
      # it_behaves_like 'ToMsg', nil, 'devise_token_auth.sessions.bad_credentials', nil
    end
    shared_examples_for '[未ログイン]有効なパラメータ（未ロック）' do
      let(:send_user)  { send_user_unlocked }
      let(:attributes) { valid_attributes }
      it_behaves_like 'ToOK', nil, true
      # it_behaves_like 'ToOK', true, false
      it_behaves_like 'ToMsg', nil, nil, nil
      # it_behaves_like 'ToMsg', nil, nil, 'devise.sessions.signed_in'
    end
    shared_examples_for '[ログイン中/削除予約済み]有効なパラメータ（未ロック）' do
      let(:send_user)  { send_user_unlocked }
      let(:attributes) { valid_attributes }
      it_behaves_like 'ToOK', nil, true
      # it_behaves_like 'ToNG', 401
      it_behaves_like 'ToMsg', nil, nil, nil
      # it_behaves_like 'ToMsg', nil, 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン]有効なパラメータ（ロック中）' do
      let(:send_user)  { send_user_locked }
      let(:attributes) { valid_attributes }
      it_behaves_like 'ToNG', 401
      # it_behaves_like 'ToNG', 422
      it_behaves_like 'ToMsg', 'devise.mailer.unlock_instructions.account_lock_msg', nil, nil
      # it_behaves_like 'ToMsg', nil, 'devise.failure.locked', nil
    end
    shared_examples_for '[ログイン中/削除予約済み]有効なパラメータ（ロック中）' do
      let(:send_user)  { send_user_locked }
      let(:attributes) { valid_attributes }
      it_behaves_like 'ToNG', 401
      it_behaves_like 'ToMsg', 'devise.mailer.unlock_instructions.account_lock_msg', nil, nil
      # it_behaves_like 'ToMsg', nil, 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン]有効なパラメータ（メール未確認）' do
      let(:send_user)  { send_user_unconfirmed }
      let(:attributes) { valid_attributes }
      it_behaves_like 'ToNG', 401
      # it_behaves_like 'ToNG', 422
      it_behaves_like 'ToMsg', 'devise.failure.unconfirmed', nil, nil
      # it_behaves_like 'ToMsg', nil, 'devise.failure.unconfirmed', nil
    end
    shared_examples_for '[ログイン中/削除予約済み]有効なパラメータ（メール未確認）' do
      let(:send_user)  { send_user_unconfirmed }
      let(:attributes) { valid_attributes }
      it_behaves_like 'ToNG', 401
      it_behaves_like 'ToMsg', 'devise_token_auth.sessions.not_confirmed', nil, nil
      # it_behaves_like 'ToMsg', nil, 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン]有効なパラメータ（メールアドレス変更中）' do
      let(:send_user)  { send_user_email_changed }
      let(:attributes) { valid_attributes }
      it_behaves_like 'ToOK', nil, true
      # it_behaves_like 'ToOK', true, false
      it_behaves_like 'ToMsg', nil, nil, nil
      # it_behaves_like 'ToMsg', nil, nil, 'devise.sessions.signed_in'
    end
    shared_examples_for '[ログイン中/削除予約済み]有効なパラメータ（メールアドレス変更中）' do
      let(:send_user)  { send_user_email_changed }
      let(:attributes) { valid_attributes }
      it_behaves_like 'ToOK', nil, true
      # it_behaves_like 'ToNG', 401
      it_behaves_like 'ToMsg', nil, nil, nil
      # it_behaves_like 'ToMsg', nil, 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン]有効なパラメータ（削除予約済み）' do
      let(:send_user)  { send_user_destroy_reserved }
      let(:attributes) { valid_attributes }
      it_behaves_like 'ToOK', nil, true
      # it_behaves_like 'ToOK', true, false
      it_behaves_like 'ToMsg', nil, nil, nil
      # it_behaves_like 'ToMsg', nil, nil, 'devise.sessions.signed_in'
    end
    shared_examples_for '[ログイン中/削除予約済み]有効なパラメータ（削除予約済み）' do
      let(:send_user)  { send_user_destroy_reserved }
      let(:attributes) { valid_attributes }
      it_behaves_like 'ToOK', nil, true
      # it_behaves_like 'ToNG', 401
      it_behaves_like 'ToMsg', nil, nil, nil
      # it_behaves_like 'ToMsg', nil, 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン]無効なパラメータ' do
      let(:send_user)  { send_user_unlocked }
      let(:attributes) { invalid_attributes }
      it_behaves_like 'ToNG', 401
      # it_behaves_like 'ToNG', 422
      it_behaves_like 'ToMsg', 'devise_token_auth.sessions.bad_credentials', nil, nil
      # it_behaves_like 'ToMsg', nil, 'devise.failure.invalid', nil
    end
    shared_examples_for '[ログイン中/削除予約済み]無効なパラメータ' do
      let(:send_user)  { send_user_unlocked }
      let(:attributes) { invalid_attributes }
      it_behaves_like 'ToNG', 401
      it_behaves_like 'ToMsg', 'devise_token_auth.sessions.bad_credentials', nil, nil
      # it_behaves_like 'ToMsg', nil, 'devise.failure.already_authenticated', nil
    end

    context '未ログイン' do
      let(:auth_headers) { nil }
      it_behaves_like '[*]パラメータなし'
      it_behaves_like '[未ログイン]有効なパラメータ（未ロック）'
      it_behaves_like '[未ログイン]有効なパラメータ（ロック中）'
      it_behaves_like '[未ログイン]有効なパラメータ（メール未確認）'
      it_behaves_like '[未ログイン]有効なパラメータ（メールアドレス変更中）'
      it_behaves_like '[未ログイン]有効なパラメータ（削除予約済み）'
      it_behaves_like '[未ログイン]無効なパラメータ'
    end
    context 'ログイン中' do
      include_context 'authログイン処理'
      it_behaves_like '[*]パラメータなし'
      it_behaves_like '[ログイン中/削除予約済み]有効なパラメータ（未ロック）'
      it_behaves_like '[ログイン中/削除予約済み]有効なパラメータ（ロック中）'
      it_behaves_like '[ログイン中/削除予約済み]有効なパラメータ（メール未確認）'
      it_behaves_like '[ログイン中/削除予約済み]有効なパラメータ（メールアドレス変更中）'
      it_behaves_like '[ログイン中/削除予約済み]有効なパラメータ（削除予約済み）'
      it_behaves_like '[ログイン中/削除予約済み]無効なパラメータ'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'authログイン処理', :user_destroy_reserved
      it_behaves_like '[*]パラメータなし'
      it_behaves_like '[ログイン中/削除予約済み]有効なパラメータ（未ロック）'
      it_behaves_like '[ログイン中/削除予約済み]有効なパラメータ（ロック中）'
      it_behaves_like '[ログイン中/削除予約済み]有効なパラメータ（メール未確認）'
      it_behaves_like '[ログイン中/削除予約済み]有効なパラメータ（メールアドレス変更中）'
      it_behaves_like '[ログイン中/削除予約済み]有効なパラメータ（削除予約済み）'
      it_behaves_like '[ログイン中/削除予約済み]無効なパラメータ'
    end
  end

  # DELETE /users/auth/sign_out ログアウト(処理)
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  describe 'DELETE #destroy' do
    subject { delete destroy_user_auth_session_path, headers: auth_headers }

    # テスト内容
    shared_examples_for 'ToOK' do
      it '成功ステータス。対象項目が一致する' do
        is_expected.to eq(200)
        expect(JSON.parse(response.body)['success']).to eq(true)
      end
    end
    shared_examples_for 'ToNG' do |code|
      it '失敗ステータス。対象項目が一致する' do
        is_expected.to eq(code) # 方針: 401: 未ログイン
        expect(JSON.parse(response.body)['success']).to eq(false)
      end
    end
    shared_examples_for 'ToMsg' do |error_msg, alert, notice|
      it '対象のメッセージと一致する。認証ヘッダがない' do
        subject
        response_json = JSON.parse(response.body)
        expect(response_json['errors'].to_s).to error_msg.present? ? include(I18n.t(error_msg)) : be_blank # 方針: 廃止して、alertへ

        expect(response_json['alert']).to alert.present? ? eq(I18n.t(alert)) : be_nil # 方針: 追加
        expect(response_json['notice']).to notice.present? ? eq(I18n.t(notice)) : be_nil # 方針: 追加

        expect(response.header['uid']).to be_nil
        expect(response.header['client']).to be_nil
        expect(response.header['access-token']).to be_nil
      end
    end

    # テストケース
    context '未ログイン' do
      let(:auth_headers) { nil }
      it_behaves_like 'ToNG', 404
      # it_behaves_like 'ToNG', 401
      it_behaves_like 'ToMsg', 'devise_token_auth.sessions.user_not_found', nil, nil
      # it_behaves_like 'ToMsg', nil, 'devise_token_auth.sessions.user_not_found', nil
    end
    context 'ログイン中' do
      include_context 'authログイン処理'
      it_behaves_like 'ToOK'
      it_behaves_like 'ToMsg', nil, nil, nil
      # it_behaves_like 'ToMsg', nil, nil, 'devise.sessions.signed_out'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'authログイン処理', :user_destroy_reserved
      it_behaves_like 'ToOK'
      it_behaves_like 'ToMsg', nil, nil, nil
      # it_behaves_like 'ToMsg', nil, nil, 'devise.sessions.signed_out'
    end
  end
end
