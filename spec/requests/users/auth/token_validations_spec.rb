require 'rails_helper'

RSpec.describe 'Users::Auth::TokenValidations', type: :request do
  # GET /users/auth/validate_token トークン検証(処理)
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  describe 'GET #validate_token' do
    subject { get user_auth_validate_token_path, headers: auth_headers }

    # テスト内容
    shared_examples_for 'ToOK' do |id_present|
      it '成功ステータス。対象項目が一致する。認証ヘッダがある' do
        is_expected.to eq(200)
        response_json = JSON.parse(response.body)
        expect(response_json['success']).to eq(true)

        expect(response_json['data']['id'].present?).to eq(id_present) # 方針: 廃止
        expect(response_json['data']['name']).to eq(user.name)

        expect(response.header['uid']).not_to be_nil
        expect(response.header['client']).not_to be_nil
        expect(response.header['access-token']).not_to be_nil
      end
    end
    shared_examples_for 'ToNG' do |code|
      it '失敗ステータス。対象項目が一致する。認証ヘッダがない' do
        is_expected.to eq(code) # 方針: 401: 未ログイン
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
    context '未ログイン' do
      let(:auth_headers) { nil }
      it_behaves_like 'ToNG', 401
      it_behaves_like 'ToMsg', 'devise_token_auth.token_validations.invalid', nil, nil
      # it_behaves_like 'ToMsg', nil, 'devise_token_auth.token_validations.invalid', nil
    end
    context 'ログイン中' do
      include_context 'authログイン処理'
      it_behaves_like 'ToOK', true
      # it_behaves_like 'ToOK', false
      it_behaves_like 'ToMsg', nil, nil, nil
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'authログイン処理', :user_destroy_reserved
      it_behaves_like 'ToOK', true
      # it_behaves_like 'ToOK', false
      it_behaves_like 'ToMsg', nil, nil, nil
    end
  end
end
