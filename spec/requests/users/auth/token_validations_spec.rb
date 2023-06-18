require 'rails_helper'

RSpec.describe 'Users::Auth::TokenValidations', type: :request do
  let(:response_json) { JSON.parse(response.body) }

  # テスト内容（共通）
  shared_examples_for 'ToMsg' do |error_msg, alert, notice|
    let(:subject_format) { :json }
    let(:accept_headers) { ACCEPT_INC_JSON }
    it '対象のメッセージと一致する' do
      subject
      expect(response_json['errors'].to_s).to error_msg.present? ? include(get_locale(error_msg)) : be_blank # 方針: 廃止して、alertへ
      expect(response_json['alert']).to alert.present? ? eq(get_locale(alert)) : be_nil # 方針: 追加
      expect(response_json['notice']).to notice.present? ? eq(get_locale(notice)) : be_nil # 方針: 追加
    end
  end

  # GET /users/auth/validate_token(.json) トークン検証API(処理)
  # テストパターン
  #   未ログイン, ログイン中, APIログイン中
  #   ＋URLの拡張子: .json, ない
  #   ＋Acceptヘッダ: JSONが含まれる, JSONが含まれない
  describe 'GET #validate_token' do
    subject { get user_auth_validate_token_path(format: subject_format), headers: auth_headers.merge(accept_headers) }

    include_context 'Authテスト内容'
    let(:current_user) { user }

    # テスト内容
    shared_examples_for 'ToOK(json/json)' do # |id_present|
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      it 'HTTPステータスが200。対象項目が一致する。認証ヘッダがある' do
        is_expected.to eq(200)
        # expect(response_json['success']).to eq(true)
        # expect(response_json['data']['id'].present?).to eq(id_present) # 方針: 廃止
        # expect(response_json['data']['name']).to eq(user.name)
        # expect(response_json['data']['image']).not_to be_nil
        expect_success_json
        expect_exist_auth_header
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

    shared_examples_for 'ToOK' do # |id_present|
      it_behaves_like 'ToNG(html/html)', 406
      it_behaves_like 'ToNG(html/json)', 406
      it_behaves_like 'ToNG(json/html)', 406
      it_behaves_like 'ToOK(json/json)' # , id_present
    end
    shared_examples_for 'ToNG' do |code|
      it_behaves_like 'ToNG(html/html)', 406
      it_behaves_like 'ToNG(html/json)', 406
      it_behaves_like 'ToNG(json/html)', 406
      it_behaves_like 'ToNG(json/json)', code
    end

    # テストケース
    shared_examples_for '[未ログイン/ログイン中]' do
      it_behaves_like 'ToNG', 401
      # it_behaves_like 'ToMsg', 'devise_token_auth.token_validations.invalid', nil, nil
      it_behaves_like 'ToMsg', nil, 'devise_token_auth.token_validations.invalid', nil
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
      # it_behaves_like 'ToOK', true
      it_behaves_like 'ToOK', false
      it_behaves_like 'ToMsg', nil, nil, nil
    end
  end
end
