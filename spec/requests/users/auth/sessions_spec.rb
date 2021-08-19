require 'rails_helper'

RSpec.describe 'Users::Auth::Sessions', type: :request do
  # POST /users/auth/sign_in ログイン(処理)
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, 未ログイン（削除予約済み）, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  #   パラメータなし, 有効なパラメータ, 無効なパラメータ → 事前にデータ作成
  describe 'POST #create' do
    shared_context '有効なパラメータ' do
      let!(:params) { { email: user.email, password: user.password } }
    end
    shared_context '無効なパラメータ' do
      let!(:params) { { email: user.email, password: nil } }
    end

    # テスト内容
    shared_examples_for 'ToOK' do # |alert, notice|
      it '成功ステータス・JSONデータ・ヘッダ' do
        post create_user_auth_session_path, params: params, headers: headers
        expect(response).to be_successful

        response_json = JSON.parse(response.body)
        expect(response_json['success']).to be_nil
        # expect(response_json['success']).to eq(true)
        expect(response_json['errors']).to be_nil
        # expect(response_json['data']['id']).to be_nil
        expect(response_json['data']['name']).to eq(user.name)

        # expect(response_json['alert']).to alert.present? ? eq(I18n.t(alert)) : be_nil
        # expect(response_json['notice']).to notice.present? ? eq(I18n.t(notice)) : be_nil

        expect(response.header['uid']).not_to be_nil
        expect(response.header['client']).not_to be_nil
        expect(response.header['access-token']).not_to be_nil
      end
    end
    shared_examples_for 'ToNG' do # |alert, notice|
      it '失敗ステータス・JSONデータ・ヘッダ' do
        post create_user_auth_session_path, params: params, headers: headers
        expect(response).to have_http_status(401)
        # expect(response).to have_http_status(422)

        response_json = JSON.parse(response.body)
        expect(response_json['success']).to eq(false)
        expect(response_json['errors']).not_to be_nil
        expect(response_json['data']).to be_nil

        # expect(response_json['alert']).to alert.present? ? eq(I18n.t(alert)) : be_nil
        # expect(response_json['notice']).to notice.present? ? eq(I18n.t(notice)) : be_nil

        expect(response.header['uid']).to be_nil
        expect(response.header['client']).to be_nil
        expect(response.header['access-token']).to be_nil
      end
    end

    # テストケース
    shared_examples_for '[*]パラメータなし' do
      let!(:params) { nil }
      it_behaves_like 'ToNG', nil, nil
    end
    shared_examples_for '[未ログイン]有効なパラメータ' do
      include_context '有効なパラメータ'
      it_behaves_like 'ToOK', nil, 'devise.sessions.signed_in'
    end
    shared_examples_for '[ログイン中/削除予約済み]有効なパラメータ' do
      include_context '有効なパラメータ'
      it_behaves_like 'ToOK', nil, nil
      # it_behaves_like 'ToNG', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン]無効なパラメータ' do
      include_context '無効なパラメータ'
      it_behaves_like 'ToNG', nil, nil
    end
    shared_examples_for '[ログイン中/削除予約済み]無効なパラメータ' do
      include_context '無効なパラメータ'
      it_behaves_like 'ToNG', 'devise.failure.already_authenticated', nil
    end

    context '未ログイン' do
      include_context 'ユーザー作成'
      let!(:headers) { nil }
      it_behaves_like '[*]パラメータなし'
      it_behaves_like '[未ログイン]有効なパラメータ'
      it_behaves_like '[未ログイン]無効なパラメータ'
    end
    context '未ログイン（削除予約済み）' do
      include_context 'ユーザー作成', true
      let!(:headers) { nil }
      # it_behaves_like '[*]パラメータなし' # Tips: 未ログインと同じ
      it_behaves_like '[未ログイン]有効なパラメータ'
      it_behaves_like '[未ログイン]無効なパラメータ'
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
    end
  end

  # DELETE /users/auth/sign_out ログアウト(処理)
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  describe 'DELETE #destroy' do
    # テスト内容
    shared_examples_for 'ToOK' do # |alert, notice|
      it '成功ステータス・JSONデータ・ヘッダ' do
        delete destroy_user_auth_session_path, headers: headers
        expect(response).to be_successful

        response_json = JSON.parse(response.body)
        expect(response_json['success']).to eq(true)
        expect(response_json['errors']).to be_nil

        # expect(response_json['alert']).to alert.present? ? eq(I18n.t(alert)) : be_nil
        # expect(response_json['notice']).to notice.present? ? eq(I18n.t(notice)) : be_nil

        expect(response.header['uid']).to be_nil
        expect(response.header['client']).to be_nil
        expect(response.header['access-token']).to be_nil
      end
    end
    shared_examples_for 'ToNG' do # |alert, notice|
      it '失敗ステータス・JSONデータ・ヘッダ' do
        delete destroy_user_auth_session_path, headers: headers
        expect(response).to have_http_status(404)
        # expect(response).to have_http_status(401)

        response_json = JSON.parse(response.body)
        expect(response_json['success']).to eq(false)
        expect(response_json['errors']).not_to be_nil

        # expect(response_json['alert']).to alert.present? ? eq(I18n.t(alert)) : be_nil
        # expect(response_json['notice']).to notice.present? ? eq(I18n.t(notice)) : be_nil

        expect(response.header['uid']).to be_nil
        expect(response.header['client']).to be_nil
        expect(response.header['access-token']).to be_nil
      end
    end

    # テストケース
    context '未ログイン' do
      let!(:headers) { nil }
      it_behaves_like 'ToNG', nil, 'devise.sessions.already_signed_out'
    end
    context 'ログイン中' do
      include_context 'authログイン処理'
      let!(:headers) { auth_headers }
      it_behaves_like 'ToOK', nil, 'devise.sessions.signed_out'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'authログイン処理', true
      let!(:headers) { auth_headers }
      it_behaves_like 'ToOK', nil, 'devise.sessions.signed_out'
    end
  end
end
