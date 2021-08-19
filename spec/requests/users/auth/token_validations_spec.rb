require 'rails_helper'

RSpec.describe 'Users::Auth::TokenValidations', type: :request do
  # GET /users/auth/validate_token トークン検証(処理)
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  describe 'GET #validate_token' do
    # テスト内容
    shared_examples_for 'ToOK' do |alert, notice|
      it '成功ステータス・JSONデータ・ヘッダ' do
        get user_auth_validate_token_path, headers: headers
        expect(response).to be_successful

        response_json = JSON.parse(response.body)
        expect(response_json['success']).to eq(true)
        expect(response_json['errors']).to be_nil
        # expect(response_json['data']['id']).to be_nil
        expect(response_json['data']['name']).to eq(user.name)

        expect(response_json['alert']).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(response_json['notice']).to notice.present? ? eq(I18n.t(notice)) : be_nil

        expect(response.header['uid']).not_to be_nil
        expect(response.header['client']).not_to be_nil
        expect(response.header['access-token']).not_to be_nil
      end
    end
    shared_examples_for 'ToNG' do |alert, notice|
      it '失敗ステータス・JSONデータ・ヘッダ' do
        get user_auth_validate_token_path, headers: headers
        expect(response).to have_http_status(401)
        # expect(response).to have_http_status(422)

        response_json = JSON.parse(response.body)
        expect(response_json['success']).to eq(false)
        expect(response_json['errors']).not_to be_nil
        expect(response_json['data']).to be_nil

        expect(response_json['alert']).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(response_json['notice']).to notice.present? ? eq(I18n.t(notice)) : be_nil

        expect(response.header['uid']).to be_nil
        expect(response.header['client']).to be_nil
        expect(response.header['access-token']).to be_nil
      end
    end

    # テストケース
    context '未ログイン' do
      let!(:headers) { nil }
      it_behaves_like 'ToNG', nil, nil
    end
    context 'ログイン中' do
      include_context 'authログイン処理'
      let!(:headers) { auth_headers }
      it_behaves_like 'ToOK', nil, nil
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'authログイン処理', true
      let!(:headers) { auth_headers }
      it_behaves_like 'ToOK', nil, nil
    end
  end
end
