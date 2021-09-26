require 'rails_helper'

RSpec.describe 'Users::Auth::TokenValidations', type: :request do
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

  # GET /users/auth/validate_token(.json) トークン検証API(処理)
  # 前提条件
  #   Acceptヘッダがない
  # テストパターン
  #   URLの拡張子: ない, .json
  describe 'GET #validate_token' do
    subject { get user_auth_validate_token_path(format: subject_format) }

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
  #   未ログイン, ログイン中, APIログイン中
  describe 'GET #validate_token(json)' do
    subject { get user_auth_validate_token_path(format: subject_format), headers: auth_headers.merge(ACCEPT_JSON) }
    include_context 'Authテスト内容'
    let(:current_user) { user }

    # テスト内容
    shared_examples_for 'ToOK' do # |id_present|
      it 'HTTPステータスが200。対象項目が一致する。認証ヘッダがある' do
        is_expected.to eq(200)
        # response_json = JSON.parse(response.body)
        # expect(response_json['success']).to eq(true)
        # expect(response_json['data']['id'].present?).to eq(id_present) # 方針: 廃止
        # expect(response_json['data']['name']).to eq(user.name)
        # expect(response_json['data']['image']).not_to be_nil
        expect_success_json
        expect_exist_auth_header
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
      it_behaves_like 'ToNG', 401
      # it_behaves_like 'ToMsg', 'devise_token_auth.token_validations.invalid', nil, nil
      it_behaves_like 'ToMsg', nil, 'devise_token_auth.token_validations.invalid', nil
    end
    shared_examples_for 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like 'ToNG', 401
      # it_behaves_like 'ToMsg', 'devise_token_auth.token_validations.invalid', nil, nil
      it_behaves_like 'ToMsg', nil, 'devise_token_auth.token_validations.invalid', nil
    end
    shared_examples_for 'APIログイン中' do
      include_context 'APIログイン処理'
      # it_behaves_like 'ToOK', true
      it_behaves_like 'ToOK', false
      it_behaves_like 'ToMsg', nil, nil, nil
    end

    context 'URLの拡張子がない' do
      let(:subject_format) { nil }
      it_behaves_like '未ログイン'
      it_behaves_like 'ログイン中'
      it_behaves_like 'APIログイン中'
    end
    context 'URLの拡張子が.json' do
      let(:subject_format) { :json }
      it_behaves_like '未ログイン'
      it_behaves_like 'ログイン中'
      it_behaves_like 'APIログイン中'
    end
  end
end
