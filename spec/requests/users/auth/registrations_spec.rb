require 'rails_helper'

RSpec.describe 'Users::Auth::Registrations', type: :request do
  # テスト内容（共通）
  shared_examples_for 'ToMsg' do |error_class, errors_count, error_msg, message, alert, notice|
    it '対象のメッセージと一致する' do
      subject
      response_json = JSON.parse(response.body)
      expect(response_json['errors'].to_s).to error_msg.present? ? include(I18n.t(error_msg)) : be_blank
      expect(response_json['errors'].class).to eq(error_class) # 方針: バリデーション(Hash)のみ、他はalertへ
      expect(response_json['errors']&.count).to errors_count.positive? ? eq(errors_count) : be_nil
      expect(response_json['message']).to message.present? ? eq(I18n.t(message)) : be_nil # 方針: 廃止して、noticeへ

      expect(response_json['alert']).to alert.present? ? eq(I18n.t(alert)) : be_nil # 方針: 追加
      expect(response_json['notice']).to notice.present? ? eq(I18n.t(notice)) : be_nil # 方針: 追加
    end
  end

  # POST /users/auth/sign_up(.json) アカウント登録API(処理)
  # 前提条件
  #   Acceptヘッダがない
  # テストパターン
  #   URLの拡張子: ない, .json
  describe 'POST #create' do
    subject { post create_user_auth_registration_path(format: subject_format) }

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
  #   パラメータなし, 有効なパラメータ, 無効なパラメータ, URLがない, URLがホワイトリストにない
  describe 'POST #create(json)' do
    subject { post create_user_auth_registration_path(format: subject_format), params: attributes, headers: auth_headers.merge(ACCEPT_JSON) }
    let(:new_user)   { FactoryBot.attributes_for(:user) }
    let(:exist_user) { FactoryBot.create(:user) }
    let(:valid_attributes)       { { name: new_user[:name], email: new_user[:email], password: new_user[:password], confirm_success_url: FRONT_SITE_URL } }
    let(:invalid_attributes)     { { name: exist_user.name, email: exist_user.email, password: exist_user.password, confirm_success_url: FRONT_SITE_URL } }
    let(:invalid_nil_attributes) { { name: new_user[:name], email: new_user[:email], password: new_user[:password], confirm_success_url: nil } }
    let(:invalid_bad_attributes) { { name: new_user[:name], email: new_user[:email], password: new_user[:password], confirm_success_url: BAD_SITE_URL } }
    include_context 'Authテスト内容'
    let(:current_user) { User.find_by!(email: attributes[:email]) }

    # テスト内容
    shared_examples_for 'OK' do
      it '作成・対象項目が設定される。メールが送信される' do
        expect do
          subject
          expect(current_user.name).to eq(attributes[:name]) # メールアドレス、氏名

          expect(ActionMailer::Base.deliveries.count).to eq(1)
          expect(ActionMailer::Base.deliveries[0].subject).to eq(get_subject('devise.mailer.confirmation_instructions.subject')) # メールアドレス確認のお願い
        end.to change(User, :count).by(1)
      end
    end
    shared_examples_for 'NG' do
      it '作成されない。メールが送信されない' do
        expect { subject }.to change(User, :count).by(0) && change(ActionMailer::Base.deliveries, :count).by(0)
      end
    end

    shared_examples_for 'ToOK' do # |status, success, data_present|
      it 'HTTPステータスが200。対象項目が一致する。認証ヘッダがない' do
        is_expected.to eq(200)
        # response_json = JSON.parse(response.body)
        # expect(response_json['status']).to eq(status) # 方針: 廃止して、successに統一
        # expect(response_json['success']).to eq(success)
        # expect(response_json['data'].present?).to eq(data_present) # 方針: 廃止
        expect_success_json
        expect_not_exist_auth_header
      end
    end
    shared_examples_for 'ToNG' do |code| # , status, success, data_present|
      it "HTTPステータスが#{code}。対象項目が一致する。認証ヘッダがない" do
        is_expected.to eq(code) # 方針(優先順): 401: ログイン中, 400:パラメータなし, 422: 無効なパラメータ・状態
        # response_json = JSON.parse(response.body)
        # expect(response_json['status']).to eq(status) # 方針: 廃止して、successに統一
        # expect(response_json['success']).to eq(success)
        # expect(response_json['data'].present?).to eq(data_present) # 方針: 廃止
        expect_failure_json
        expect_not_exist_auth_header
      end
    end

    # テストケース
    shared_examples_for '[未ログイン/ログイン中]パラメータなし' do
      let(:attributes) { nil }
      it_behaves_like 'NG'
      # it_behaves_like 'ToNG', 422, 'error', false, false
      it_behaves_like 'ToNG', 400, nil, false, false
      # it_behaves_like 'ToMsg', Array, 1, 'errors.messages.validate_sign_up_params', nil, nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'errors.messages.validate_sign_up_params', nil
    end
    shared_examples_for '[APIログイン中]パラメータなし' do
      let(:attributes) { nil }
      it_behaves_like 'NG'
      # it_behaves_like 'ToNG', 422, 'error', false, false
      it_behaves_like 'ToNG', 401, nil, false, false
      # it_behaves_like 'ToMsg', Array, 1, 'errors.messages.validate_sign_up_params', nil, nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン/ログイン中]有効なパラメータ' do
      let(:attributes) { valid_attributes }
      it_behaves_like 'OK'
      # it_behaves_like 'ToOK', 'success', nil, true
      it_behaves_like 'ToOK', nil, true, false
      # it_behaves_like 'ToMsg', NilClass, 0, nil, nil, nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, nil, 'devise.registrations.signed_up_but_unconfirmed'
    end
    shared_examples_for '[APIログイン中]有効なパラメータ' do
      let(:attributes) { valid_attributes }
      # it_behaves_like 'OK'
      it_behaves_like 'NG'
      # it_behaves_like 'ToOK', 'success', nil, true
      it_behaves_like 'ToNG', 401, nil, false, false
      # it_behaves_like 'ToMsg', NilClass, 0, nil, nil, nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン/ログイン中]無効なパラメータ' do
      let(:attributes) { invalid_attributes }
      it_behaves_like 'NG'
      # it_behaves_like 'ToNG', 422, 'error', nil, true
      it_behaves_like 'ToNG', 422, nil, false, false
      # it_behaves_like 'ToMsg', Hash, 2, 'activerecord.errors.models.user.attributes.email.taken', nil, nil, nil
      it_behaves_like 'ToMsg', Hash, 2, 'activerecord.errors.models.user.attributes.email.taken', nil, 'errors.messages.not_saved.one', nil
    end
    shared_examples_for '[APIログイン中]無効なパラメータ' do
      let(:attributes) { invalid_attributes }
      it_behaves_like 'NG'
      # it_behaves_like 'ToNG', 422, 'error', nil, true
      it_behaves_like 'ToNG', 401, nil, false, false
      # it_behaves_like 'ToMsg', Hash, 2, 'activerecord.errors.models.user.attributes.email.taken', nil, nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン/ログイン中]URLがない' do
      let(:attributes) { invalid_nil_attributes }
      it_behaves_like 'NG'
      # it_behaves_like 'ToNG', 422, 'error', false, true
      it_behaves_like 'ToNG', 422, nil, false, false
      # it_behaves_like 'ToMsg', Array, 1, 'devise_token_auth.registrations.missing_confirm_success_url', nil, nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise_token_auth.registrations.missing_confirm_success_url', nil
    end
    shared_examples_for '[APIログイン中]URLがない' do
      let(:attributes) { invalid_nil_attributes }
      it_behaves_like 'NG'
      # it_behaves_like 'ToNG', 422, 'error', false, true
      it_behaves_like 'ToNG', 401, nil, false, false
      # it_behaves_like 'ToMsg', Array, 1, 'devise_token_auth.registrations.missing_confirm_success_url', nil, nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン/ログイン中]URLがホワイトリストにない' do
      let(:attributes) { invalid_bad_attributes }
      it_behaves_like 'NG'
      # it_behaves_like 'ToNG', 422, 'error', false, true
      it_behaves_like 'ToNG', 422, nil, false, false
      # it_behaves_like 'ToMsg', Array, 1, 'devise_token_auth.registrations.redirect_url_not_allowed', nil, nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise_token_auth.registrations.redirect_url_not_allowed', nil
    end
    shared_examples_for '[APIログイン中]URLがホワイトリストにない' do
      let(:attributes) { invalid_bad_attributes }
      it_behaves_like 'NG'
      # it_behaves_like 'ToNG', 422, 'error', false, true
      it_behaves_like 'ToNG', 401, nil, false, false
      # it_behaves_like 'ToMsg', Array, 1, 'devise_token_auth.registrations.redirect_url_not_allowed', nil, nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise.failure.already_authenticated', nil
    end

    shared_examples_for '未ログイン' do
      include_context '未ログイン処理'
      it_behaves_like '[未ログイン/ログイン中]パラメータなし'
      it_behaves_like '[未ログイン/ログイン中]有効なパラメータ'
      it_behaves_like '[未ログイン/ログイン中]無効なパラメータ'
      it_behaves_like '[未ログイン/ログイン中]URLがない'
      it_behaves_like '[未ログイン/ログイン中]URLがホワイトリストにない'
    end
    shared_examples_for 'ログイン中' do
      include_context '未ログイン処理'
      it_behaves_like '[未ログイン/ログイン中]パラメータなし'
      it_behaves_like '[未ログイン/ログイン中]有効なパラメータ'
      it_behaves_like '[未ログイン/ログイン中]無効なパラメータ'
      it_behaves_like '[未ログイン/ログイン中]URLがない'
      it_behaves_like '[未ログイン/ログイン中]URLがホワイトリストにない'
    end
    shared_examples_for 'APIログイン中' do
      include_context 'APIログイン処理'
      it_behaves_like '[APIログイン中]パラメータなし'
      it_behaves_like '[APIログイン中]有効なパラメータ'
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

  # PUT(PATCH) /users/auth/update(.json) 登録情報変更API(処理)
  # 前提条件
  #   Acceptヘッダがない
  # テストパターン
  #   URLの拡張子: ない, .json
  describe 'PUT #update' do
    subject { put update_user_auth_registration_path(format: subject_format) }

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
  #   パラメータなし, 有効なパラメータ（変更なし, あり）, 無効なパラメータ
  describe 'PUT #update(json)' do
    subject { put update_user_auth_registration_path(format: subject_format), params: attributes, headers: auth_headers.merge(ACCEPT_JSON) }
    let(:new_user)   { FactoryBot.attributes_for(:user) }
    let(:exist_user) { FactoryBot.create(:user) }
    let(:nochange_attributes) { { name: user.name, email: user.email, password: user.password } }
    let(:valid_attributes)    { { name: new_user[:name], email: new_user[:email], password: new_user[:password] } }
    let(:invalid_attributes)  { { name: exist_user.name, email: exist_user.email, password: exist_user.password } }
    include_context 'Authテスト内容'
    let(:current_user) { User.find(user.id) }

    # テスト内容
    shared_examples_for 'OK' do |change_email|
      it '対象項目が変更される。対象のメールが送信される' do
        subject
        expect(current_user.unconfirmed_email).to change_email ? eq(attributes[:email]) : eq(user.unconfirmed_email) # 確認待ちメールアドレス
        expect(current_user.name).to eq(attributes[:name]) # 氏名
        expect(current_user.image.url).to eq(user.image.url) # 画像 # Tips: 変更されない

        expect(ActionMailer::Base.deliveries.count).to eq(change_email ? 3 : 1)
        expect(ActionMailer::Base.deliveries[0].subject).to eq(get_subject('devise.mailer.email_changed.subject')) if change_email # メールアドレス変更受け付けのお知らせ
        expect(ActionMailer::Base.deliveries[change_email ? 1 : 0].subject).to eq(get_subject('devise.mailer.password_change.subject')) # パスワード変更完了のお知らせ
        expect(ActionMailer::Base.deliveries[2].subject).to eq(get_subject('devise.mailer.confirmation_instructions.subject')) if change_email # メールアドレス確認のお願い
      end
    end
    shared_examples_for 'NG' do
      it '対象項目が変更されない。メールが送信されない' do
        subject
        expect(current_user.unconfirmed_email).to eq(user.unconfirmed_email) # 確認待ちメールアドレス
        expect(current_user.name).to eq(user.name) # 氏名
        expect(current_user.image.url).to eq(user.image.url) # 画像

        expect(ActionMailer::Base.deliveries.count).to eq(0)
      end
    end

    shared_examples_for 'ToOK' do # |status, success, id_present|
      it 'HTTPステータスが200。対象項目が一致する。認証ヘッダがある' do
        is_expected.to eq(200)
        # response_json = JSON.parse(response.body)
        # expect(response_json['status']).to eq(status) # 方針: 廃止して、successに統一
        # expect(response_json['success']).to eq(success)
        # expect(response_json['data']['id'].present?).to eq(id_present) # 方針: 廃止
        # expect(response_json['data']['name']).to eq(attributes[:name])
        # expect(response_json['data']['image']).not_to be_nil
        expect_success_json
        expect_exist_auth_header
      end
    end
    shared_examples_for 'ToNG' do |code| # , status, success|
      it "HTTPステータスが#{code}。対象項目が一致する。認証ヘッダがない" do
        is_expected.to eq(code) # 方針(優先順): 401: 未ログイン, 400:パラメータなし, 422: 無効なパラメータ・状態
        # response_json = JSON.parse(response.body)
        # expect(response_json['status']).to eq(status) # 方針: 廃止して、successに統一
        # expect(response_json['success']).to eq(success)
        # expect(response_json['data']).to be_nil
        expect_failure_json
        expect_not_exist_auth_header
      end
    end

    # テストケース
    shared_examples_for '[未ログイン/ログイン中]パラメータなし' do
      let(:attributes) { nil }
      # it_behaves_like 'NG' # Tips: 未ログインの為、対象がない
      # it_behaves_like 'ToNG', 422, 'error', false
      it_behaves_like 'ToNG', 401, nil, false
      # it_behaves_like 'ToMsg', Array, 1, 'errors.messages.validate_account_update_params', nil, nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise.failure.unauthenticated', nil
    end
    shared_examples_for '[APIログイン中/削除予約済み]パラメータなし' do
      let(:attributes) { nil }
      it_behaves_like 'NG'
      # it_behaves_like 'ToNG', 422, 'error', false
      it_behaves_like 'ToNG', 400, nil, false
      # it_behaves_like 'ToMsg', Array, 1, 'errors.messages.validate_account_update_params', nil, nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'errors.messages.validate_account_update_params', nil
    end
    shared_examples_for '[APIログイン中]有効なパラメータ（変更なし）' do
      let(:attributes) { nochange_attributes }
      it_behaves_like 'OK', false
      # it_behaves_like 'ToOK', 'success', nil, true
      it_behaves_like 'ToOK', nil, true, false
      # it_behaves_like 'ToMsg', NilClass, 0, nil, nil, nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, nil, 'devise.registrations.updated'
    end
    shared_examples_for '[削除予約済み]有効なパラメータ（変更なし）' do
      let(:attributes) { nochange_attributes }
      # it_behaves_like 'OK', false
      it_behaves_like 'NG'
      # it_behaves_like 'ToOK', 'success', nil, true
      it_behaves_like 'ToNG', 422, nil, false
      # it_behaves_like 'ToMsg', NilClass, 0, nil, nil, nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'alert.user.destroy_reserved', nil
    end
    shared_examples_for '[未ログイン/ログイン中]有効なパラメータ（変更あり）' do
      let(:attributes) { valid_attributes }
      # it_behaves_like 'NG' # Tips: 未ログインの為、対象がない
      # it_behaves_like 'ToNG', 404, 'error', false
      it_behaves_like 'ToNG', 401, nil, false
      # it_behaves_like 'ToMsg', Array, 1, 'devise_token_auth.registrations.user_not_found', nil, nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise.failure.unauthenticated', nil
    end
    shared_examples_for '[APIログイン中]有効なパラメータ（変更あり）' do
      let(:attributes) { valid_attributes }
      it_behaves_like 'OK', true
      # it_behaves_like 'ToOK', 'success', nil, true
      it_behaves_like 'ToOK', nil, true, false
      # it_behaves_like 'ToMsg', NilClass, 0, nil, nil, nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, nil, 'devise.registrations.update_needs_confirmation'
    end
    shared_examples_for '[削除予約済み]有効なパラメータ（変更あり）' do
      let(:attributes) { valid_attributes }
      # it_behaves_like 'OK', true
      it_behaves_like 'NG'
      # it_behaves_like 'ToOK', 'success', nil, true
      it_behaves_like 'ToNG', 422, nil, false
      # it_behaves_like 'ToMsg', NilClass, 0, nil, nil, nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'alert.user.destroy_reserved', nil
    end
    shared_examples_for '[未ログイン/ログイン中]無効なパラメータ' do
      let(:attributes) { invalid_attributes }
      # it_behaves_like 'NG' # Tips: 未ログインの為、対象がない
      # it_behaves_like 'ToNG', 404, 'error', false
      it_behaves_like 'ToNG', 401, nil, false
      # it_behaves_like 'ToMsg', Array, 1, 'devise_token_auth.registrations.user_not_found', nil, nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise.failure.unauthenticated', nil
    end
    shared_examples_for '[APIログイン中]無効なパラメータ' do
      let(:attributes) { invalid_attributes }
      # it_behaves_like 'OK', true
      it_behaves_like 'NG'
      # it_behaves_like 'ToOK', 'success', nil, true
      it_behaves_like 'ToNG', 422, nil, false
      # it_behaves_like 'ToMsg', NilClass, 0, nil, nil, nil, nil
      it_behaves_like 'ToMsg', Hash, 2, 'activerecord.errors.models.user.attributes.email.exist', nil, 'errors.messages.not_saved.one', nil
    end
    shared_examples_for '[削除予約済み]無効なパラメータ' do
      let(:attributes) { invalid_attributes }
      # it_behaves_like 'OK', true
      it_behaves_like 'NG'
      # it_behaves_like 'ToOK', 'success', nil, true
      it_behaves_like 'ToNG', 422, nil, false
      # it_behaves_like 'ToMsg', NilClass, 0, nil, nil, nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'alert.user.destroy_reserved', nil
    end

    shared_examples_for '未ログイン' do
      include_context '未ログイン処理'
      it_behaves_like '[未ログイン/ログイン中]パラメータなし'
      # it_behaves_like '[未ログイン/ログイン中]有効なパラメータ（変更なし）' # Tips: 未ログインの為、対象がない
      it_behaves_like '[未ログイン/ログイン中]有効なパラメータ（変更あり）'
      it_behaves_like '[未ログイン/ログイン中]無効なパラメータ'
    end
    shared_examples_for 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[未ログイン/ログイン中]パラメータなし'
      # it_behaves_like '[未ログイン/ログイン中]有効なパラメータ（変更なし）' # Tips: 未ログインの為、対象がない
      it_behaves_like '[未ログイン/ログイン中]有効なパラメータ（変更あり）'
      it_behaves_like '[未ログイン/ログイン中]無効なパラメータ'
    end
    shared_examples_for 'APIログイン中' do
      include_context 'APIログイン処理', :user, true
      it_behaves_like '[APIログイン中/削除予約済み]パラメータなし'
      it_behaves_like '[APIログイン中]有効なパラメータ（変更なし）'
      it_behaves_like '[APIログイン中]有効なパラメータ（変更あり）'
      it_behaves_like '[APIログイン中]無効なパラメータ'
    end
    shared_examples_for 'APIログイン中（削除予約済み）' do
      include_context 'APIログイン処理', :user_destroy_reserved, true
      it_behaves_like '[APIログイン中/削除予約済み]パラメータなし'
      it_behaves_like '[削除予約済み]有効なパラメータ（変更なし）'
      it_behaves_like '[削除予約済み]有効なパラメータ（変更あり）'
      it_behaves_like '[削除予約済み]無効なパラメータ'
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

  # PUT(PATCH) /users/auth/image(.json) 画像変更API(処理)
  # 前提条件
  #   Acceptヘッダがない
  # テストパターン
  #   URLの拡張子: ない, .json
  describe 'PUT #image_update' do
    subject { put update_user_auth_image_registration_path(format: subject_format) }

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
  #   有効なパラメータ, 無効なパラメータ
  describe 'PUT #image_update(json)' do
    subject { put update_user_auth_image_registration_path(format: subject_format), params: attributes, headers: auth_headers.merge(ACCEPT_JSON) }
    let(:valid_attributes)   { { image: fixture_file_upload(TEST_IMAGE_FILE, TEST_IMAGE_TYPE) } }
    let(:invalid_attributes) { nil }
    include_context 'Authテスト内容'
    let(:current_user) { User.find(user.id) }

    # テスト内容
    shared_examples_for 'OK' do
      it '画像が変更される' do
        subject
        expect(current_user.image.url).not_to eq(user.image.url)
      end
    end
    shared_examples_for 'NG' do
      it '画像が変更されない' do
        subject
        expect(current_user.image.url).to eq(user.image.url)
      end
    end

    shared_examples_for 'ToOK' do
      it 'HTTPステータスが200。対象項目が一致する。認証ヘッダがある' do
        is_expected.to eq(200)
        expect_success_json
        expect_exist_auth_header
      end
    end
    shared_examples_for 'ToNG' do |code|
      it "HTTPステータスが#{code}。対象項目が一致する。認証ヘッダがない" do
        is_expected.to eq(code) # 方針(優先順): 401: 未ログイン, 400:パラメータなし, 422: 無効なパラメータ・状態
        expect_failure_json
        expect_not_exist_auth_header
      end
    end

    # テストケース
    shared_examples_for '[未ログイン/ログイン中]有効なパラメータ' do
      let(:attributes) { valid_attributes }
      # it_behaves_like 'NG' # Tips: 未ログインの為、対象がない
      it_behaves_like 'ToNG', 401
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise.failure.unauthenticated', nil
    end
    shared_examples_for '[APIログイン中]有効なパラメータ' do
      let(:attributes) { valid_attributes }
      it_behaves_like 'OK'
      it_behaves_like 'ToOK'
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, nil, 'notice.user.image_update'
      after do
        current_user.remove_image!
        current_user.save!
      end
    end
    shared_examples_for '[削除予約済み]有効なパラメータ' do
      let(:attributes) { valid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToNG', 422
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'alert.user.destroy_reserved', nil
    end
    shared_examples_for '[未ログイン/ログイン中]無効なパラメータ' do
      let(:attributes) { invalid_attributes }
      # it_behaves_like 'NG' # Tips: 未ログインの為、対象がない
      it_behaves_like 'ToNG', 401
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise.failure.unauthenticated', nil
    end
    shared_examples_for '[APIログイン中]無効なパラメータ' do
      let(:attributes) { invalid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToNG', 422
      it_behaves_like 'ToMsg', Hash, 2, 'errors.messages.image_update_blank', nil, 'errors.messages.not_saved.one', nil
    end
    shared_examples_for '[削除予約済み]無効なパラメータ' do
      let(:attributes) { invalid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToNG', 422
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'alert.user.destroy_reserved', nil
    end

    shared_examples_for '未ログイン' do
      include_context '未ログイン処理'
      it_behaves_like '[未ログイン/ログイン中]有効なパラメータ'
      it_behaves_like '[未ログイン/ログイン中]無効なパラメータ'
    end
    shared_examples_for 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[未ログイン/ログイン中]有効なパラメータ'
      it_behaves_like '[未ログイン/ログイン中]無効なパラメータ'
    end
    shared_examples_for 'APIログイン中' do
      include_context 'APIログイン処理'
      it_behaves_like '[APIログイン中]有効なパラメータ'
      it_behaves_like '[APIログイン中]無効なパラメータ'
    end
    shared_examples_for 'APIログイン中（削除予約済み）' do
      include_context 'APIログイン処理', :user_destroy_reserved
      it_behaves_like '[削除予約済み]有効なパラメータ'
      it_behaves_like '[削除予約済み]無効なパラメータ'
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

  # DELETE /users/auth/image(.json) 画像削除API(処理)
  # 前提条件
  #   Acceptヘッダがない
  # テストパターン
  #   URLの拡張子: ない, .json
  describe 'DELETE #image_destroy' do
    subject { delete delete_user_auth_image_registration_path(format: subject_format) }

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
  describe 'DELETE #image_destroy(json)' do
    subject { delete delete_user_auth_image_registration_path(format: subject_format), headers: auth_headers.merge(ACCEPT_JSON) }
    include_context 'Authテスト内容'
    let(:current_user) { User.find(user.id) }

    # テスト内容
    shared_examples_for 'OK' do
      it '画像が削除される' do
        subject
        expect(current_user.image.url).to be_nil
      end
    end
    shared_examples_for 'NG' do
      it '画像が変更されない' do
        subject
        expect(current_user.image.url).to eq(user.image.url)
      end
    end

    shared_examples_for 'ToOK' do
      it 'HTTPステータスが200。対象項目が一致する。認証ヘッダがある' do
        is_expected.to eq(200)
        expect_success_json
        expect_exist_auth_header
      end
    end
    shared_examples_for 'ToNG' do |code|
      it "HTTPステータスが#{code}。対象項目が一致する。認証ヘッダがない" do
        is_expected.to eq(code) # 方針(優先順): 401: 未ログイン, 400:パラメータなし, 422: 無効なパラメータ・状態
        expect_failure_json
        expect_not_exist_auth_header
      end
    end

    # テストケース
    shared_examples_for '未ログイン' do
      include_context '未ログイン処理'
      # it_behaves_like 'NG' # Tips: 未ログインの為、対象がない
      it_behaves_like 'ToNG', 401
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise.failure.unauthenticated', nil
    end
    shared_examples_for 'ログイン中' do
      include_context 'ログイン処理', :user, true
      it_behaves_like 'NG'
      it_behaves_like 'ToNG', 401
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise.failure.unauthenticated', nil
    end
    shared_examples_for 'APIログイン中' do
      include_context 'APIログイン処理', :user, true
      it_behaves_like 'OK'
      it_behaves_like 'ToOK'
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, nil, 'notice.user.image_destroy'
    end
    shared_examples_for 'APIログイン中（削除予約済み）' do
      include_context 'APIログイン処理', :user_destroy_reserved, true
      it_behaves_like 'NG'
      it_behaves_like 'ToNG', 422
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'alert.user.destroy_reserved', nil
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

  # DELETE /users/auth/destroy(.json) アカウント削除API(処理)
  # 前提条件
  #   Acceptヘッダがない
  # テストパターン
  #   URLの拡張子: ない, .json
  describe 'DELETE #destroy' do
    subject { delete destroy_user_auth_registration_path(format: subject_format) }

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
    subject { delete destroy_user_auth_registration_path(format: subject_format), headers: auth_headers.merge(ACCEPT_JSON) }
    include_context 'Authテスト内容'
    let(:current_user) { User.find(user.id) }

    # テスト内容
    shared_examples_for 'OK' do
      # it '削除される' do
      #   expect { subject }.to change(User, :count).by(-1)
      # end
      let!(:start_time) { Time.current.floor }
      it "削除依頼日時が現在日時に、削除予定日時が#{Settings['destroy_schedule_days']}日後に変更される" do
        subject
        expect(current_user.destroy_requested_at).to be_between(start_time, Time.current)
        expect(current_user.destroy_schedule_at).to be_between(start_time + Settings['destroy_schedule_days'].days,
                                                               Time.current + Settings['destroy_schedule_days'].days)
      end
    end
    shared_examples_for 'NG' do
      # it '削除されない' do
      #   expect { subject }.to change(User, :count).by(0)
      # end
      let!(:before_destroy_requested_at) { user.destroy_requested_at }
      let!(:before_destroy_schedule_at)  { user.destroy_schedule_at }
      it '削除依頼日時・削除予定日時が変更されない' do
        subject
        expect(current_user.destroy_requested_at).to eq(before_destroy_requested_at)
        expect(current_user.destroy_schedule_at).to eq(before_destroy_schedule_at)
      end
    end

    shared_examples_for 'ToOK' do # |status, success|
      it 'HTTPステータスが200。対象項目が一致する。認証ヘッダがない' do
        is_expected.to eq(200)
        # response_json = JSON.parse(response.body)
        # expect(response_json['status']).to eq(status) # 方針: 廃止して、successに統一
        # expect(response_json['success']).to eq(success)
        # expect(response_json['data']).to be_nil
        expect_success_json
        expect_not_exist_auth_header
      end
    end
    shared_examples_for 'ToNG' do |code, _status, _success|
      it "HTTPステータスが#{code}。対象項目が一致する。認証ヘッダがない" do
        is_expected.to eq(code) # 方針(優先順): 401: 未ログイン, 422: 無効なパラメータ・状態
        # response_json = JSON.parse(response.body)
        # expect(response_json['status']).to eq(status) # 方針: 廃止して、successに統一
        # expect(response_json['success']).to eq(success)
        # expect(response_json['data']).to be_nil
        expect_failure_json
        expect_not_exist_auth_header
      end
    end

    # テストケース
    shared_examples_for '未ログイン' do
      include_context '未ログイン処理'
      # it_behaves_like 'NG' # Tips: 未ログインの為、対象がない
      # it_behaves_like 'ToNG', 404, 'error', false
      it_behaves_like 'ToNG', 401, nil, false
      # it_behaves_like 'ToMsg', NilClass, 0, 'devise_token_auth.registrations.account_to_destroy_not_found', nil, nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise.failure.unauthenticated', nil
    end
    shared_examples_for 'ログイン中' do
      include_context 'ログイン処理'
      # it_behaves_like 'NG' # Tips: 未ログインの為、対象がない
      # it_behaves_like 'ToNG', 404, 'error', false
      it_behaves_like 'ToNG', 401, nil, false
      # it_behaves_like 'ToMsg', NilClass, 0, 'devise_token_auth.registrations.account_to_destroy_not_found', nil, nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise.failure.unauthenticated', nil
    end
    shared_examples_for 'APIログイン中' do
      include_context 'APIログイン処理'
      it_behaves_like 'OK'
      # it_behaves_like 'ToOK', 'success', nil
      it_behaves_like 'ToOK', nil, true
      # it_behaves_like 'ToMsg', NilClass, 0, nil, 'devise_token_auth.registrations.account_with_uid_destroyed', nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, nil, 'devise.registrations.destroy_reserved'
    end
    shared_examples_for 'APIログイン中（削除予約済み）' do
      include_context 'APIログイン処理', :user_destroy_reserved
      # it_behaves_like 'OK'
      it_behaves_like 'NG'
      # it_behaves_like 'ToOK', 'success', nil
      it_behaves_like 'ToNG', 422, nil, false
      # it_behaves_like 'ToMsg', NilClass, 0, nil, 'devise_token_auth.registrations.account_with_uid_destroyed', nil, nil
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'alert.user.destroy_reserved', nil
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

  # DELETE /users/auth/undo_delete(.json) アカウント削除取り消しAPI(処理)
  # 前提条件
  #   Acceptヘッダがない
  # テストパターン
  #   URLの拡張子: ない, .json
  describe 'DELETE #undo_destroy' do
    subject { delete destroy_undo_user_auth_registration_path(format: subject_format) }

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
  describe 'DELETE #undo_destroy(json)' do
    subject { delete destroy_undo_user_auth_registration_path(format: subject_format), headers: auth_headers.merge(ACCEPT_JSON) }
    include_context 'Authテスト内容'
    let(:current_user) { User.find(user.id) }

    # テスト内容
    shared_examples_for 'OK' do
      it '削除依頼日時・削除予定日時がなしに変更される' do
        subject
        expect(current_user.destroy_requested_at).to be_nil
        expect(current_user.destroy_schedule_at).to be_nil
      end
    end
    shared_examples_for 'NG' do
      it '削除依頼日時・削除予定日時が変更されない' do
        subject
        expect(current_user.destroy_requested_at).to eq(user.destroy_requested_at)
        expect(current_user.destroy_schedule_at).to eq(user.destroy_schedule_at)
      end
    end

    shared_examples_for 'ToOK' do
      it 'HTTPステータスが200。対象項目が一致する。認証ヘッダがある' do
        is_expected.to eq(200)
        expect_success_json
        expect_exist_auth_header
      end
    end
    shared_examples_for 'ToNG' do |code|
      it "HTTPステータスが#{code}。対象項目が一致する。認証ヘッダがない" do
        is_expected.to eq(code) # 方針(優先順): 401: 未ログイン, 400:パラメータなし, 422: 無効なパラメータ・状態
        expect_failure_json
        expect_not_exist_auth_header
      end
    end

    # テストケース
    shared_examples_for '未ログイン' do
      include_context '未ログイン処理'
      # it_behaves_like 'NG' # Tips: 未ログインの為、対象がない
      it_behaves_like 'ToNG', 401
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise.failure.unauthenticated', nil
    end
    shared_examples_for 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like 'NG'
      it_behaves_like 'ToNG', 401
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise.failure.unauthenticated', nil
    end
    shared_examples_for 'APIログイン中' do
      include_context 'APIログイン処理'
      it_behaves_like 'NG'
      it_behaves_like 'ToNG', 422
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'alert.user.not_destroy_reserved', nil
    end
    shared_examples_for 'APIログイン中（削除予約済み）' do
      include_context 'APIログイン処理', :user_destroy_reserved
      it_behaves_like 'OK'
      it_behaves_like 'ToOK'
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, nil, 'devise.registrations.undo_destroy_reserved'
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
