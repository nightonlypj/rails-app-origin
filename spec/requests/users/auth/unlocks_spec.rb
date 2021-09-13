require 'rails_helper'

RSpec.describe 'Users::Auth::Unlocks', type: :request do
  # POST /users/auth/unlock(.json) アカウントロック解除API[メール再送](処理)
  # 前提条件
  #   Acceptヘッダがない
  # テストパターン
  #   URLの拡張子: ない, .json
  describe 'POST #create' do
    subject { post create_user_auth_unlock_path(format: subject_format) }

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
  #   パラメータなし, 有効なパラメータ（ロック中, 未ロック）, 無効なパラメータ, URLがない, URLがホワイトリストにない
  describe 'POST #create(json)' do
    subject { post create_user_auth_unlock_path(format: subject_format), params: attributes, headers: auth_headers.merge(ACCEPT_JSON) }
    let(:send_user_locked)   { FactoryBot.create(:user_locked) }
    let(:send_user_unlocked) { FactoryBot.create(:user) }
    let(:not_user)           { FactoryBot.attributes_for(:user) }
    let(:valid_attributes)       { { email: send_user.email, redirect_url: FRONT_SITE_URL } }
    let(:invalid_attributes)     { { email: not_user[:email], redirect_url: FRONT_SITE_URL } }
    let(:invalid_nil_attributes) { { email: send_user_locked.email, redirect_url: nil } }
    let(:invalid_bad_attributes) { { email: send_user_locked.email, redirect_url: BAD_SITE_URL } }

    # テスト内容
    shared_examples_for 'OK' do
      it 'メールが送信される' do
        subject
        expect(ActionMailer::Base.deliveries.count).to eq(1)
        expect(ActionMailer::Base.deliveries[0].subject).to eq(get_subject('devise.mailer.unlock_instructions.subject')) # アカウントロックのお知らせ
      end
    end
    shared_examples_for 'NG' do
      it 'メールが送信されない' do
        expect { subject }.to change(ActionMailer::Base.deliveries, :count).by(0)
      end
    end

    shared_examples_for 'ToOK' do
      it 'HTTPステータスが200。対象項目が一致する' do
        is_expected.to eq(200)
        expect(JSON.parse(response.body)['success']).to eq(true)
      end
    end
    shared_examples_for 'ToNG' do |code|
      it "HTTPステータスが#{code}。対象項目が一致する" do
        is_expected.to eq(code) # 方針(優先順): 401: ログイン中, 400:パラメータなし, 422: 無効なパラメータ・状態
        expect(JSON.parse(response.body)['success']).to eq(false)
      end
    end
    shared_examples_for 'ToMsg' do |error_class, errors_count, error_msg, message, alert, notice|
      it '対象のメッセージと一致する。認証ヘッダがない' do
        subject
        response_json = JSON.parse(response.body)
        expect(response_json['errors'].to_s).to error_msg.present? ? include(I18n.t(error_msg)) : be_blank
        expect(response_json['errors'].class).to eq(error_class) # 方針: バリデーション(Hash)のみ、他はalertへ
        expect(response_json['errors']&.count).to errors_count.positive? ? eq(errors_count) : be_nil
        expect(response_json['message']).to message.present? ? eq(I18n.t(message)) : be_nil # 方針: 廃止して、noticeへ

        expect(response_json['alert']).to alert.present? ? eq(I18n.t(alert)) : be_nil # 方針: 追加
        expect(response_json['notice']).to notice.present? ? eq(I18n.t(notice)) : be_nil # 方針: 追加

        expect(response.header['uid']).to be_nil
        expect(response.header['client']).to be_nil
        expect(response.header['access-token']).to be_nil
      end
    end

    # テストケース
    shared_examples_for '[未ログイン/ログイン中]パラメータなし' do
      let(:attributes) { nil }
      it_behaves_like 'NG'
      it_behaves_like 'ToNG', 422
      # it_behaves_like 'ToNG', 400
      it_behaves_like 'ToMsg', Array, 1, 'devise_token_auth.unlocks.not_allowed_redirect_url', nil, nil, nil
      # it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'errors.messages.validate_unlock_params', nil
    end
    shared_examples_for '[APIログイン中]パラメータなし' do
      let(:attributes) { nil }
      it_behaves_like 'NG'
      it_behaves_like 'ToNG', 422
      # it_behaves_like 'ToNG', 401
      it_behaves_like 'ToMsg', Array, 1, 'devise_token_auth.unlocks.not_allowed_redirect_url', nil, nil, nil
      # it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン/ログイン中]有効なパラメータ（ロック中）' do
      let(:send_user)  { send_user_locked }
      let(:attributes) { valid_attributes }
      it_behaves_like 'OK'
      it_behaves_like 'ToOK', nil, 'devise.unlocks.send_instructions'
      it_behaves_like 'ToMsg', NilClass, 0, nil, 'devise_token_auth.unlocks.sended', nil, nil
      # it_behaves_like 'ToMsg', NilClass, 0, nil, nil, nil, 'devise_token_auth.unlocks.sended'
    end
    shared_examples_for '[APIログイン中]有効なパラメータ（ロック中）' do
      let(:send_user)  { send_user_locked }
      let(:attributes) { valid_attributes }
      it_behaves_like 'OK'
      # it_behaves_like 'NG'
      it_behaves_like 'ToOK'
      # it_behaves_like 'ToNG', 401
      it_behaves_like 'ToMsg', NilClass, 0, nil, 'devise_token_auth.unlocks.sended', nil, nil
      # it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン/ログイン中]有効なパラメータ（未ロック）' do
      let(:send_user)  { send_user_unlocked }
      let(:attributes) { valid_attributes }
      it_behaves_like 'OK'
      # it_behaves_like 'NG'
      it_behaves_like 'ToOK'
      # it_behaves_like 'ToNG', 422
      it_behaves_like 'ToMsg', NilClass, 0, nil, 'devise_token_auth.unlocks.sended', nil, nil
      # it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'errors.messages.not_locked', nil
    end
    shared_examples_for '[APIログイン中]有効なパラメータ（未ロック）' do
      let(:send_user)  { send_user_unlocked }
      let(:attributes) { valid_attributes }
      it_behaves_like 'OK'
      # it_behaves_like 'NG'
      it_behaves_like 'ToOK'
      # it_behaves_like 'ToNG', 401
      it_behaves_like 'ToMsg', NilClass, 0, nil, 'devise_token_auth.unlocks.sended', nil, nil
      # it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン/ログイン中]無効なパラメータ' do
      let(:attributes) { invalid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToNG', 404
      # it_behaves_like 'ToNG', 422
      it_behaves_like 'ToMsg', Array, 1, 'devise_token_auth.unlocks.user_not_found', nil, nil, nil
      # it_behaves_like 'ToMsg', Hash, 2, 'devise_token_auth.unlocks.user_not_found', nil, 'errors.messages.not_saved.one', nil
    end
    shared_examples_for '[APIログイン中]無効なパラメータ' do
      let(:attributes) { invalid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToNG', 404
      # it_behaves_like 'ToNG', 401
      it_behaves_like 'ToMsg', Array, 1, 'devise_token_auth.unlocks.user_not_found', nil, nil, nil
      # it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン/ログイン中]URLがない' do
      let(:attributes) { invalid_nil_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToNG', 401
      # it_behaves_like 'ToNG', 422
      it_behaves_like 'ToMsg', Array, 1, 'devise_token_auth.unlocks.missing_redirect_url', nil, nil, nil
      # it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise_token_auth.unlocks.missing_redirect_url', nil
    end
    shared_examples_for '[APIログイン中]URLがない' do
      let(:attributes) { invalid_nil_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToNG', 401
      it_behaves_like 'ToMsg', Array, 1, 'devise_token_auth.unlocks.missing_redirect_url', nil, nil, nil
      # it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン/ログイン中]URLがホワイトリストにない' do
      let(:attributes) { invalid_bad_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToNG', 422
      it_behaves_like 'ToMsg', Array, 1, 'devise_token_auth.unlocks.not_allowed_redirect_url', nil, nil, nil
      # it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise_token_auth.unlocks.not_allowed_redirect_url', nil
    end
    shared_examples_for '[APIログイン中]URLがホワイトリストにない' do
      let(:attributes) { invalid_bad_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToNG', 422
      # it_behaves_like 'ToNG', 401
      it_behaves_like 'ToMsg', Array, 1, 'devise_token_auth.unlocks.not_allowed_redirect_url', nil, nil, nil
      # it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise.failure.already_authenticated', nil
    end

    shared_examples_for '未ログイン' do
      include_context '未ログイン処理'
      it_behaves_like '[未ログイン/ログイン中]パラメータなし'
      it_behaves_like '[未ログイン/ログイン中]有効なパラメータ（ロック中）'
      it_behaves_like '[未ログイン/ログイン中]有効なパラメータ（未ロック）'
      it_behaves_like '[未ログイン/ログイン中]無効なパラメータ'
      it_behaves_like '[未ログイン/ログイン中]URLがない'
      it_behaves_like '[未ログイン/ログイン中]URLがホワイトリストにない'
    end
    shared_examples_for 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[未ログイン/ログイン中]パラメータなし'
      it_behaves_like '[未ログイン/ログイン中]有効なパラメータ（ロック中）'
      it_behaves_like '[未ログイン/ログイン中]有効なパラメータ（未ロック）'
      it_behaves_like '[未ログイン/ログイン中]無効なパラメータ'
      it_behaves_like '[未ログイン/ログイン中]URLがない'
      it_behaves_like '[未ログイン/ログイン中]URLがホワイトリストにない'
    end
    shared_examples_for 'APIログイン中' do
      include_context 'APIログイン処理'
      it_behaves_like '[APIログイン中]パラメータなし'
      it_behaves_like '[APIログイン中]有効なパラメータ（ロック中）'
      it_behaves_like '[APIログイン中]有効なパラメータ（未ロック）'
      it_behaves_like '[APIログイン中]無効なパラメータ'
      it_behaves_like '[APIログイン中]URLがない'
      it_behaves_like '[APIログイン中]URLがホワイトリストにない'
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

  # GET /users/auth/unlock アカウントロック解除(処理)
  # 前提条件
  #   以外（URLの拡張子がない, Acceptヘッダがない）
  # テストパターン
  #   URLの拡張子: ない, .json
  #   Acceptヘッダ: ない, JSON
  describe 'GET #show(json)' do
    subject { get user_auth_unlock_path(format: subject_format), headers: accept_headers }

    # テストケース
    context 'URLの拡張子がない, AcceptヘッダがJSON' do
      let(:subject_format) { nil }
      let(:accept_headers) { ACCEPT_JSON }
      it_behaves_like 'To406'
    end
    context 'URLの拡張子が.json, Acceptヘッダがない' do
      let(:subject_format) { :json }
      let(:accept_headers) { nil }
      it_behaves_like 'To406'
    end
    context 'URLの拡張子が.json, AcceptヘッダがJSON' do
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_JSON }
      it_behaves_like 'To406'
    end
  end
  # 前提条件
  #   URLの拡張子がない, Acceptヘッダがない
  # テストパターン
  #   未ログイン, ログイン中, APIログイン中
  #   トークン: 存在する, 存在しない, ない, 空
  #   ロック日時: ない（未ロック）, ある（ロック中）
  #   ＋リダイレクトURL: ある, ない, ホワイトリストにない
  describe 'GET #show' do
    subject { get user_auth_unlock_path(unlock_token: unlock_token, redirect_url: @redirect_url), headers: auth_headers }

    # テスト内容
    shared_examples_for 'OK' do
      it '[リダイレクトURLがある]アカウントロック日時がなしに変更される' do
        @redirect_url = FRONT_SITE_URL
        subject
        expect(User.find(send_user.id).locked_at).to be_nil
      end
      it '[リダイレクトURLがない]アカウントロック日時がなしに変更されない' do
        # it '[リダイレクトURLがない]アカウントロック日時がなしに変更される' do
        @redirect_url = nil
        subject
        expect(User.find(send_user.id).locked_at).to eq(send_user.locked_at)
        # expect(User.find(send_user.id).locked_at).to be_nil
      end
      it '[リダイレクトURLがホワイトリストにない]アカウントロック日時がなしに変更されない' do
        # it '[リダイレクトURLがホワイトリストにない]アカウントロック日時がなしに変更される' do
        @redirect_url = BAD_SITE_URL
        subject
        expect(User.find(send_user.id).locked_at).to eq(send_user.locked_at)
        # expect(User.find(send_user.id).locked_at).to be_nil
      end
    end
    shared_examples_for 'NG' do
      it '[リダイレクトURLがある]アカウントロック日時が変更されない' do
        @redirect_url = FRONT_SITE_URL
        subject
        expect(User.find(send_user.id).locked_at).to eq(send_user.locked_at)
      end
      it '[リダイレクトURLがない]アカウントロック日時が変更されない' do
        @redirect_url = nil
        subject
        expect(User.find(send_user.id).locked_at).to eq(send_user.locked_at)
      end
      it '[リダイレクトURLがホワイトリストにない]アカウントロック日時が変更されない' do
        @redirect_url = BAD_SITE_URL
        subject
        expect(User.find(send_user.id).locked_at).to eq(send_user.locked_at)
      end
    end

    shared_examples_for 'ToOK' do # |alert, notice|
      it '[リダイレクトURLがある]指定URL（成功パラメータ）にリダイレクトする' do
        @redirect_url = FRONT_SITE_URL
        param = '?unlock=true'
        # param += "&alert=#{I18n.t(alert)}" if alert.present?
        # param += "&notice=#{I18n.t(notice)}" if notice.present?
        is_expected.to redirect_to("#{FRONT_SITE_URL}#{param}")
      end
      it '[リダイレクトURLがない]HTTPステータスが422。対象項目が一致する' do
        # it '[リダイレクトURLがない]成功ページにリダイレクトする' do
        @redirect_url = nil
        is_expected.to eq(422)
        response_json = JSON.parse(response.body)
        expect(response_json['success']).to eq(false)
        expect(response_json['errors']).not_to be_nil
        expect(response_json['message']).to be_nil
        # is_expected.to redirect_to('/unlock_success.html?not')
      end
      it '[リダイレクトURLがホワイトリストにない]HTTPステータスが422。対象項目が一致する' do
        # it '[リダイレクトURLがホワイトリストにない]成功ページにリダイレクトする' do
        @redirect_url = BAD_SITE_URL
        is_expected.to eq(422)
        response_json = JSON.parse(response.body)
        expect(response_json['success']).to eq(false)
        expect(response_json['errors']).not_to be_nil
        expect(response_json['message']).to be_nil
        # is_expected.to redirect_to('/unlock_success.html?bad')
      end
    end
    shared_examples_for 'ToNG' do |alert, notice|
      it '[リダイレクトURLがある]指定URL（失敗パラメータ）にリダイレクトする' do
        @redirect_url = FRONT_SITE_URL
        param = '?unlock=false'
        param += "&alert=#{I18n.t(alert)}" if alert.present?
        param += "&notice=#{I18n.t(notice)}" if notice.present?
        is_expected.to redirect_to("#{FRONT_SITE_URL}#{param}")
      end
      it '[リダイレクトURLがない]HTTPステータスが422。対象項目が一致する' do
        # it '[リダイレクトURLがない]エラーページにリダイレクトする' do
        @redirect_url = nil
        is_expected.to eq(422)
        response_json = JSON.parse(response.body)
        expect(response_json['success']).to eq(false)
        expect(response_json['errors']).not_to be_nil
        expect(response_json['message']).to be_nil
        # is_expected.to redirect_to('/unlock_error.html?not')
      end
      it '[リダイレクトURLがホワイトリストにない]HTTPステータスが422。対象項目が一致する' do
        # it '[リダイレクトURLがホワイトリストにない]エラーページにリダイレクトする' do
        @redirect_url = BAD_SITE_URL
        is_expected.to eq(422)
        response_json = JSON.parse(response.body)
        expect(response_json['success']).to eq(false)
        expect(response_json['errors']).not_to be_nil
        expect(response_json['message']).to be_nil
        # is_expected.to redirect_to('/unlock_error.html?bad')
      end
    end

    # テストケース
    shared_examples_for '[未ログイン/APIログイン中][存在する]ロック日時がない（未ロック）' do
      include_context 'アカウントロック解除トークン作成', false
      # it_behaves_like 'NG' # Tips: 元々、ロック日時がない
      it_behaves_like 'ToOK', nil, nil
      # it_behaves_like 'ToNG', nil, 'devise.unlocks.unlocked' # Tips: 既に解除済み
    end
    shared_examples_for '[ログイン中][存在する]ロック日時がない（未ロック）' do
      include_context 'アカウントロック解除トークン作成', false
      # it_behaves_like 'NG' # Tips: 元々、ロック日時がない
      it_behaves_like 'ToOK', nil, nil
      # it_behaves_like 'ToNG', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン/APIログイン中][存在しない]ロック日時がない（未ロック）' do
      # it_behaves_like 'NG' # Tips: トークンが存在しない為、ロック日時がない
      # Tips: ActionController::RoutingError: Not Found
      # it_behaves_like 'ToNG', 'activerecord.errors.models.user.attributes.unlock_token.invalid', nil
    end
    shared_examples_for '[ログイン中][存在しない]ロック日時がない（未ロック）' do
      # it_behaves_like 'NG' # Tips: トークンが存在しない為、ロック日時がない
      # Tips: ActionController::RoutingError: Not Found
      # it_behaves_like 'ToNG', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン/APIログイン中][ない/空]ロック日時がない（未ロック）' do
      # it_behaves_like 'NG' # Tips: トークンが存在しない為、ロック日時がない
      # Tips: ActionController::RoutingError: Not Found
      # it_behaves_like 'ToNG', 'activerecord.errors.models.user.attributes.unlock_token.blank', nil
    end
    shared_examples_for '[ログイン中][ない/空]ロック日時がない（未ロック）' do
      # it_behaves_like 'NG' # Tips: トークンが存在しない為、ロック日時がない
      # Tips: ActionController::RoutingError: Not Found
      # it_behaves_like 'ToNG', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン/APIログイン中][存在する]ロック日時がある（ロック中）' do
      include_context 'アカウントロック解除トークン作成', true
      it_behaves_like 'OK'
      it_behaves_like 'ToOK', nil, 'devise.unlocks.unlocked'
    end
    shared_examples_for '[ログイン中][存在する]ロック日時がある（ロック中）' do
      include_context 'アカウントロック解除トークン作成', true
      it_behaves_like 'OK'
      it_behaves_like 'ToOK', nil, nil
      # it_behaves_like 'NG'
      # it_behaves_like 'ToNG', 'devise.failure.already_authenticated', nil
    end

    shared_examples_for '[未ログイン/APIログイン中]トークンが存在する' do
      it_behaves_like '[未ログイン/APIログイン中][存在する]ロック日時がない（未ロック）'
      it_behaves_like '[未ログイン/APIログイン中][存在する]ロック日時がある（ロック中）'
    end
    shared_examples_for '[ログイン中]トークンが存在する' do
      it_behaves_like '[ログイン中][存在する]ロック日時がない（未ロック）'
      it_behaves_like '[ログイン中][存在する]ロック日時がある（ロック中）'
    end
    shared_examples_for '[未ログイン/APIログイン中]トークンが存在しない' do
      let(:unlock_token) { NOT_TOKEN }
      it_behaves_like '[未ログイン/APIログイン中][存在しない]ロック日時がない（未ロック）'
      # it_behaves_like '[未ログイン/APIログイン中][存在しない]ロック日時がある（ロック中）' # Tips: トークンが存在しない為、ロック日時がない
    end
    shared_examples_for '[ログイン中]トークンが存在しない' do
      let(:unlock_token) { NOT_TOKEN }
      it_behaves_like '[ログイン中][存在しない]ロック日時がない（未ロック）'
      # it_behaves_like '[ログイン中][存在しない]ロック日時がある（ロック中）' # Tips: トークンが存在しない為、ロック日時がない
    end
    shared_examples_for '[未ログイン/APIログイン中]トークンがない' do
      let(:unlock_token) { nil }
      it_behaves_like '[未ログイン/APIログイン中][ない/空]ロック日時がない（未ロック）'
      # it_behaves_like '[未ログイン/APIログイン中][ない]ロック日時がある（ロック中）' # Tips: トークンが存在しない為、ロック日時がない
    end
    shared_examples_for '[ログイン中]トークンがない' do
      let(:unlock_token) { nil }
      it_behaves_like '[ログイン中][ない/空]ロック日時がない（未ロック）'
      # it_behaves_like '[ログイン中][ない]ロック日時がある（ロック中）' # Tips: トークンが存在しない為、ロック日時がない
    end
    shared_examples_for '[未ログイン/APIログイン中]トークンが空' do
      let(:unlock_token) { '' }
      it_behaves_like '[未ログイン/APIログイン中][ない/空]ロック日時がない（未ロック）'
      # it_behaves_like '[未ログイン/APIログイン中][空]ロック日時がある（ロック中）' # Tips: トークンが存在しない為、ロック日時がない
    end
    shared_examples_for '[ログイン中]トークンが空' do
      let(:unlock_token) { '' }
      it_behaves_like '[ログイン中][ない/空]ロック日時がない（未ロック）'
      # it_behaves_like '[ログイン中][空]ロック日時がある（ロック中）' # Tips: トークンが存在しない為、ロック日時がない
    end

    context '未ログイン' do
      include_context '未ログイン処理'
      it_behaves_like '[未ログイン/APIログイン中]トークンが存在する'
      it_behaves_like '[未ログイン/APIログイン中]トークンが存在しない'
      it_behaves_like '[未ログイン/APIログイン中]トークンがない'
      it_behaves_like '[未ログイン/APIログイン中]トークンが空'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[ログイン中]トークンが存在する'
      it_behaves_like '[ログイン中]トークンが存在しない'
      it_behaves_like '[ログイン中]トークンがない'
      it_behaves_like '[ログイン中]トークンが空'
    end
    context 'APIログイン中' do
      include_context 'APIログイン処理'
      it_behaves_like '[未ログイン/APIログイン中]トークンが存在する'
      it_behaves_like '[未ログイン/APIログイン中]トークンが存在しない'
      it_behaves_like '[未ログイン/APIログイン中]トークンがない'
      it_behaves_like '[未ログイン/APIログイン中]トークンが空'
    end
  end
end
