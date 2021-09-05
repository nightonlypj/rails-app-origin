require 'rails_helper'

RSpec.describe 'Users::Auth::Registrations', type: :request do
  # POST /users/auth/sign_up アカウント登録(処理)
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  #   パラメータなし, 有効なパラメータ, 無効なパラメータ, URLがない, URLがホワイトリストにない → 事前にデータ作成
  describe 'POST #create' do
    subject { post create_user_auth_registration_path, params: attributes, headers: auth_headers }
    let(:new_user)   { FactoryBot.attributes_for(:user) }
    let(:exist_user) { FactoryBot.create(:user) }
    let(:valid_attributes)       { { name: new_user[:name], email: new_user[:email], password: new_user[:password], confirm_success_url: FRONT_SITE_URL } }
    let(:invalid_attributes)     { { name: exist_user.name, email: exist_user.email, password: exist_user.password, confirm_success_url: FRONT_SITE_URL } }
    let(:invalid_nil_attributes) { { name: new_user[:name], email: new_user[:email], password: new_user[:password], confirm_success_url: nil } }
    let(:invalid_bad_attributes) { { name: new_user[:name], email: new_user[:email], password: new_user[:password], confirm_success_url: BAD_SITE_URL } }

    # テスト内容
    shared_examples_for 'OK' do
      it '作成・対象項目が設定される。メールが送信される' do
        expect do
          subject
          expect(User.find_by(email: attributes[:email]).name).to eq(attributes[:name]) # 氏名

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

    shared_examples_for 'ToOK' do |status, success, data_present|
      it '成功ステータス。対象項目が一致する' do
        is_expected.to eq(200)
        response_json = JSON.parse(response.body)
        expect(response_json['status']).to eq(status) # 方針: 廃止して、successに統一
        expect(response_json['success']).to eq(success)

        expect(response_json['data'].present?).to eq(data_present) # 方針: 廃止
      end
    end
    shared_examples_for 'ToNG' do |code, status, success, data_present|
      it '失敗ステータス。対象項目が一致する' do
        is_expected.to eq(code) # 方針(優先順): 401: ログイン中, 400:パラメータなし, 422: 無効なパラメータ・状態
        response_json = JSON.parse(response.body)
        expect(response_json['status']).to eq(status) # 方針: 廃止して、successに統一
        expect(response_json['success']).to eq(success)

        expect(response_json['data'].present?).to eq(data_present) # 方針: 廃止
      end
    end
    shared_examples_for 'ToMsg' do |error_class, errors_count, error_msg, alert, notice|
      it '対象のメッセージと一致する。認証ヘッダがない' do
        subject
        response_json = JSON.parse(response.body)
        expect(response_json['errors'].to_s).to error_msg.present? ? include(I18n.t(error_msg)) : be_blank
        expect(response_json['errors'].class).to eq(error_class) # 方針: バリデーション(Hash)のみ、他はalertへ
        expect(response_json['errors']&.count).to errors_count.positive? ? eq(errors_count) : be_nil

        expect(response_json['alert']).to alert.present? ? eq(I18n.t(alert)) : be_nil # 方針: 追加
        expect(response_json['notice']).to notice.present? ? eq(I18n.t(notice)) : be_nil # 方針: 追加

        expect(response.header['uid']).to be_nil
        expect(response.header['client']).to be_nil
        expect(response.header['access-token']).to be_nil
      end
    end

    # テストケース
    shared_examples_for '[未ログイン]パラメータなし' do
      let(:attributes) { nil }
      it_behaves_like 'NG'
      it_behaves_like 'ToNG', 422, 'error', false, false
      # it_behaves_like 'ToNG', 400, nil, false, false
      it_behaves_like 'ToMsg', Array, 1, 'errors.messages.validate_sign_up_params', nil, nil
      # it_behaves_like 'ToMsg', NilClass, 0, nil, 'errors.messages.validate_sign_up_params', nil
    end
    shared_examples_for '[ログイン中/削除予約済み]パラメータなし' do
      let(:attributes) { nil }
      it_behaves_like 'NG'
      it_behaves_like 'ToNG', 422, 'error', false, false
      # it_behaves_like 'ToNG', 401, nil, false, false
      it_behaves_like 'ToMsg', Array, 1, 'errors.messages.validate_sign_up_params', nil, nil
      # it_behaves_like 'ToMsg', NilClass, 0, nil, 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン]有効なパラメータ' do
      let(:attributes) { valid_attributes }
      it_behaves_like 'OK'
      it_behaves_like 'ToOK', 'success', nil, true
      # it_behaves_like 'ToOK', nil, true, false
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, nil
      # it_behaves_like 'ToMsg', NilClass, 0, nil, nil, 'devise.registrations.signed_up_but_unconfirmed'
    end
    shared_examples_for '[ログイン中/削除予約済み]有効なパラメータ' do
      let(:attributes) { valid_attributes }
      it_behaves_like 'OK'
      # it_behaves_like 'NG'
      it_behaves_like 'ToOK', 'success', nil, true
      # it_behaves_like 'ToNG', 401, nil, false, false
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, nil
      # it_behaves_like 'ToMsg', NilClass, 0, nil, 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン]無効なパラメータ' do
      let(:attributes) { invalid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToNG', 422, 'error', nil, true
      # it_behaves_like 'ToNG', 422, nil, false, false
      it_behaves_like 'ToMsg', Hash, 2, 'activerecord.errors.models.user.attributes.email.taken', nil, nil
      # it_behaves_like 'ToMsg', Hash, 2, 'activerecord.errors.models.user.attributes.email.taken', 'errors.messages.not_saved.one', nil
    end
    shared_examples_for '[ログイン中/削除予約済み]無効なパラメータ' do
      let(:attributes) { invalid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToNG', 422, 'error', nil, true
      # it_behaves_like 'ToNG', 401, nil, false, false
      it_behaves_like 'ToMsg', Hash, 2, 'activerecord.errors.models.user.attributes.email.taken', nil, nil
      # it_behaves_like 'ToMsg', NilClass, 0, nil, 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン]URLがない' do
      let(:attributes) { invalid_nil_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToNG', 422, 'error', false, true
      # it_behaves_like 'ToNG', 422, 'error', false, false
      it_behaves_like 'ToMsg', Array, 1, 'devise_token_auth.registrations.missing_confirm_success_url', nil, nil
      # it_behaves_like 'ToMsg', NilClass, 0, nil, 'devise_token_auth.registrations.missing_confirm_success_url', nil
    end
    shared_examples_for '[ログイン中/削除予約済み]URLがない' do
      let(:attributes) { invalid_nil_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToNG', 422, 'error', false, true
      # it_behaves_like 'ToNG', 401, nil, false, false
      it_behaves_like 'ToMsg', Array, 1, 'devise_token_auth.registrations.missing_confirm_success_url', nil, nil
      # it_behaves_like 'ToMsg', NilClass, 0, nil, 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン]URLがホワイトリストにない' do
      let(:attributes) { invalid_bad_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToNG', 422, 'error', false, true
      # it_behaves_like 'ToNG', 422, 'error', false, false
      it_behaves_like 'ToMsg', Array, 1, 'devise_token_auth.registrations.redirect_url_not_allowed', nil, nil
      # it_behaves_like 'ToMsg', NilClass, 0, nil, 'devise_token_auth.registrations.redirect_url_not_allowed', nil
    end
    shared_examples_for '[ログイン中/削除予約済み]URLがホワイトリストにない' do
      let(:attributes) { invalid_bad_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToNG', 422, 'error', false, true
      # it_behaves_like 'ToNG', 401, nil, false, false
      it_behaves_like 'ToMsg', Array, 1, 'devise_token_auth.registrations.redirect_url_not_allowed', nil, nil
      # it_behaves_like 'ToMsg', NilClass, 0, nil, 'devise.failure.already_authenticated', nil
    end

    context '未ログイン' do
      let(:auth_headers) { nil }
      it_behaves_like '[未ログイン]パラメータなし'
      it_behaves_like '[未ログイン]有効なパラメータ'
      it_behaves_like '[未ログイン]無効なパラメータ'
      it_behaves_like '[未ログイン]URLがない'
      it_behaves_like '[未ログイン]URLがホワイトリストにない'
    end
    context 'ログイン中' do
      include_context 'authログイン処理'
      it_behaves_like '[ログイン中/削除予約済み]パラメータなし'
      it_behaves_like '[ログイン中/削除予約済み]有効なパラメータ'
      it_behaves_like '[ログイン中/削除予約済み]無効なパラメータ'
      it_behaves_like '[ログイン中/削除予約済み]URLがない'
      it_behaves_like '[ログイン中/削除予約済み]URLがホワイトリストにない'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'authログイン処理', :user_destroy_reserved
      it_behaves_like '[ログイン中/削除予約済み]パラメータなし'
      it_behaves_like '[ログイン中/削除予約済み]有効なパラメータ'
      it_behaves_like '[ログイン中/削除予約済み]無効なパラメータ'
      it_behaves_like '[ログイン中/削除予約済み]URLがない'
      it_behaves_like '[ログイン中/削除予約済み]URLがホワイトリストにない'
    end
  end

  # PUT(PATCH) /users/auth/update 登録情報変更(処理)
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  #   パラメータなし, 有効なパラメータ, 無効なパラメータ → 事前にデータ作成
  describe 'PUT #update' do
    subject { put update_user_auth_registration_path, params: attributes, headers: auth_headers }
    let(:new_user)   { FactoryBot.attributes_for(:user) }
    let(:exist_user) { FactoryBot.create(:user) }
    let(:valid_attributes)   { { name: new_user[:name], email: new_user[:email], password: new_user[:password] } }
    let(:invalid_attributes) { { name: exist_user.name, email: exist_user.email, password: exist_user.password } }

    # テスト内容
    shared_examples_for 'OK' do
      it '確認待ちメールアドレス・対象項目が変更される。対象のメールが送信される' do
        subject
        after_user = User.find(user.id)
        expect(after_user.unconfirmed_email).to eq(attributes[:email])
        expect(after_user.name).to eq(attributes[:name])

        expect(ActionMailer::Base.deliveries.count).to eq(3)
        expect(ActionMailer::Base.deliveries[0].subject).to eq(get_subject('devise.mailer.email_changed.subject')) # メールアドレス変更受け付けのお知らせ
        expect(ActionMailer::Base.deliveries[1].subject).to eq(get_subject('devise.mailer.password_change.subject')) # パスワード変更完了のお知らせ
        expect(ActionMailer::Base.deliveries[2].subject).to eq(get_subject('devise.mailer.confirmation_instructions.subject')) # メールアドレス確認のお願い
      end
    end
    shared_examples_for 'NG' do
      it '確認待ちメールアドレス・対象項目が変更されない。メールが送信されない' do
        subject
        after_user = User.find(user.id)
        expect(after_user.unconfirmed_email).to eq(user.unconfirmed_email) # 確認待ちメールアドレス
        expect(after_user.name).to eq(user.name) # 氏名

        expect(ActionMailer::Base.deliveries.count).to eq(0)
      end
    end

    shared_examples_for 'ToOK' do |status, success, id_present|
      it '成功ステータス。対象項目が一致する。認証ヘッダがある' do
        is_expected.to eq(200)
        response_json = JSON.parse(response.body)
        expect(response_json['status']).to eq(status) # 方針: 廃止して、successに統一
        expect(response_json['success']).to eq(success)

        expect(response_json['data']['id'].present?).to eq(id_present) # 方針: 廃止
        expect(response_json['data']['name']).to eq(attributes[:name])

        expect(response.header['uid']).not_to be_nil
        expect(response.header['client']).not_to be_nil
        expect(response.header['access-token']).not_to be_nil
      end
    end
    shared_examples_for 'ToNG' do |code, status, success|
      it '失敗ステータス。対象項目が一致する。認証ヘッダがない' do
        is_expected.to eq(code) # 方針(優先順): 401: 未ログイン, 400:パラメータなし, 422: 無効なパラメータ・状態
        response_json = JSON.parse(response.body)
        expect(response_json['status']).to eq(status) # 方針: 廃止して、successに統一
        expect(response_json['success']).to eq(success)

        expect(response_json['data']).to be_nil

        expect(response.header['uid']).to be_nil
        expect(response.header['client']).to be_nil
        expect(response.header['access-token']).to be_nil
      end
    end
    shared_examples_for 'ToMsg' do |error_class, errors_count, error_msg, alert, notice|
      it '対象のメッセージと一致する' do
        subject
        response_json = JSON.parse(response.body)
        expect(response_json['errors'].to_s).to error_msg.present? ? include(I18n.t(error_msg)) : be_blank
        expect(response_json['errors'].class).to eq(error_class) # 方針: バリデーション(Hash)のみ、他はalertへ
        expect(response_json['errors']&.count).to errors_count.positive? ? eq(errors_count) : be_nil

        expect(response_json['alert']).to alert.present? ? eq(I18n.t(alert)) : be_nil # 方針: 追加
        expect(response_json['notice']).to notice.present? ? eq(I18n.t(notice)) : be_nil # 方針: 追加
      end
    end

    # テストケース
    shared_examples_for '[未ログイン]パラメータなし' do
      let(:attributes) { nil }
      # it_behaves_like 'NG' # Tips: 未ログインの為、対象がない
      it_behaves_like 'ToNG', 422, 'error', false
      # it_behaves_like 'ToNG', 401, nil, false
      it_behaves_like 'ToMsg', Array, 1, 'errors.messages.validate_account_update_params', nil, nil
      # it_behaves_like 'ToMsg', NilClass, 0, nil, 'devise.failure.unauthenticated', nil
    end
    shared_examples_for '[ログイン中/削除予約済み]パラメータなし' do
      let(:attributes) { nil }
      it_behaves_like 'NG'
      it_behaves_like 'ToNG', 422, 'error', false
      # it_behaves_like 'ToNG', 400, nil, false
      it_behaves_like 'ToMsg', Array, 1, 'errors.messages.validate_account_update_params', nil, nil
      # it_behaves_like 'ToMsg', NilClass, 0, nil, 'errors.messages.validate_account_update_params', nil
    end
    shared_examples_for '[未ログイン]有効なパラメータ' do
      let(:attributes) { valid_attributes }
      # it_behaves_like 'NG' # Tips: 未ログインの為、対象がない
      it_behaves_like 'ToNG', 404, 'error', false
      # it_behaves_like 'ToNG', 401, nil, false
      it_behaves_like 'ToMsg', Array, 1, 'devise_token_auth.registrations.user_not_found', nil, nil
      # it_behaves_like 'ToMsg', NilClass, 0, nil, 'devise.failure.unauthenticated', nil
    end
    shared_examples_for '[ログイン中]有効なパラメータ' do
      let(:attributes) { valid_attributes }
      it_behaves_like 'OK'
      it_behaves_like 'ToOK', 'success', nil, true
      # it_behaves_like 'ToOK', nil, true, false
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, nil
      # it_behaves_like 'ToMsg', NilClass, 0, nil, 'devise.registrations.update_needs_confirmation', nil
    end
    shared_examples_for '[削除予約済み]有効なパラメータ' do
      let(:attributes) { valid_attributes }
      it_behaves_like 'OK'
      # it_behaves_like 'NG'
      it_behaves_like 'ToOK', 'success', nil, true
      # it_behaves_like 'ToNG', 422, nil, false
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, nil
      # it_behaves_like 'ToMsg', NilClass, 0, nil, 'alert.user.destroy_reserved', nil
    end
    shared_examples_for '[未ログイン]無効なパラメータ' do
      let(:attributes) { invalid_attributes }
      # it_behaves_like 'NG' # Tips: 未ログインの為、対象がない
      it_behaves_like 'ToNG', 404, 'error', false
      # it_behaves_like 'ToNG', 401, nil, false
      it_behaves_like 'ToMsg', Array, 1, 'devise_token_auth.registrations.user_not_found', nil, nil
      # it_behaves_like 'ToMsg', NilClass, 0, nil, 'devise.failure.unauthenticated', nil
    end
    shared_examples_for '[ログイン中]無効なパラメータ' do
      let(:attributes) { invalid_attributes }
      it_behaves_like 'OK'
      # it_behaves_like 'NG'
      it_behaves_like 'ToOK', 'success', nil, true
      # it_behaves_like 'ToNG', 422, nil, false
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, nil
      # it_behaves_like 'ToMsg', Hash, 2, 'TODO: 他の人が使っている。確認に失敗する', 'errors.messages.not_saved.one', nil
    end
    shared_examples_for '[削除予約済み]無効なパラメータ' do
      let(:attributes) { invalid_attributes }
      it_behaves_like 'OK'
      # it_behaves_like 'NG'
      it_behaves_like 'ToOK', 'success', nil, true
      # it_behaves_like 'ToNG', 422, nil, false
      it_behaves_like 'ToMsg', NilClass, 0, nil, nil, nil
      # it_behaves_like 'ToMsg', NilClass, 0, nil, 'alert.user.destroy_reserved', nil
    end

    context '未ログイン' do
      let(:auth_headers) { nil }
      it_behaves_like '[未ログイン]パラメータなし'
      it_behaves_like '[未ログイン]有効なパラメータ'
      it_behaves_like '[未ログイン]無効なパラメータ'
    end
    context 'ログイン中' do
      include_context 'authログイン処理', :user, true
      it_behaves_like '[ログイン中/削除予約済み]パラメータなし'
      it_behaves_like '[ログイン中]有効なパラメータ'
      it_behaves_like '[ログイン中]無効なパラメータ'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'authログイン処理', :user_destroy_reserved, true
      it_behaves_like '[ログイン中/削除予約済み]パラメータなし'
      it_behaves_like '[削除予約済み]有効なパラメータ'
      it_behaves_like '[削除予約済み]無効なパラメータ'
    end
  end

  # DELETE /users/auth/destroy アカウント削除(処理)
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  describe 'DELETE #destroy' do
    subject { delete destroy_user_auth_registration_path, headers: auth_headers }

    # テスト内容
    shared_examples_for 'OK' do
      it '削除される' do
        expect { subject }.to change(User, :count).by(-1)
      end
      # let!(:start_time) { Time.current - 1.second }
      # it "削除依頼日時が現在日時に、削除予定日時が#{Settings['destroy_schedule_days']}日後に変更される" do
      #   subject
      #   expect(user.destroy_requested_at).to be_between(start_time, Time.current)
      #   expect(user.destroy_schedule_at).to be_between(start_time + Settings['destroy_schedule_days'].days,
      #                                                  Time.current + Settings['destroy_schedule_days'].days)
      # end
    end
    shared_examples_for 'NG' do
      it '削除されない' do
        expect { subject }.to change(User, :count).by(0)
      end
      # let!(:before_destroy_requested_at) { user.destroy_requested_at }
      # let!(:before_destroy_schedule_at)  { user.destroy_schedule_at }
      # it '削除依頼日時・削除予定日時が変更されない' do
      #   subject
      #   expect(user.destroy_requested_at).to eq(before_destroy_requested_at)
      #   expect(user.destroy_schedule_at).to eq(before_destroy_schedule_at)
      # end
    end

    shared_examples_for 'ToOK' do |status, success|
      it '成功ステータス。対象項目が一致する' do
        is_expected.to eq(200)
        response_json = JSON.parse(response.body)
        expect(response_json['status']).to eq(status) # 方針: 廃止して、successに統一
        expect(response_json['success']).to eq(success)
      end
    end
    shared_examples_for 'ToNG' do |code, status, success|
      it '失敗ステータス。対象項目が一致する' do
        is_expected.to eq(code) # 方針(優先順): 401: 未ログイン, 422: 無効なパラメータ・状態
        response_json = JSON.parse(response.body)
        expect(response_json['status']).to eq(status) # 方針: 廃止して、successに統一
        expect(response_json['success']).to eq(success)
      end
    end
    shared_examples_for 'ToMsg' do |error_msg, message, alert, notice|
      it '対象のメッセージと一致する。認証ヘッダがない' do
        subject
        response_json = JSON.parse(response.body)
        expect(response_json['errors'].to_s).to error_msg.present? ? include(I18n.t(error_msg)) : be_blank # 方針: 廃止して、alertへ
        expect(response_json['message']).to message.present? ? eq(I18n.t(message)) : be_nil # 方針: 廃止して、noticeへ

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
      it_behaves_like 'NG'
      # it_behaves_like 'NG' # Tips: 未ログインの為、対象がない
      it_behaves_like 'ToNG', 404, 'error', false
      # it_behaves_like 'ToNG', 401, nil, false
      it_behaves_like 'ToMsg', 'devise_token_auth.registrations.account_to_destroy_not_found', nil, nil, nil
      # it_behaves_like 'ToMsg', nil, nil, 'devise.failure.unauthenticated', nil
    end
    context 'ログイン中' do
      include_context 'authログイン処理'
      it_behaves_like 'OK'
      it_behaves_like 'ToOK', 'success', nil
      # it_behaves_like 'ToOK', 'success', true
      it_behaves_like 'ToMsg', nil, 'devise_token_auth.registrations.account_with_uid_destroyed', nil, nil
      # it_behaves_like 'ToMsg', nil, nil, nil, 'devise.registrations.destroy_reserved'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'authログイン処理', :user_destroy_reserved
      it_behaves_like 'OK'
      # it_behaves_like 'NG'
      it_behaves_like 'ToOK', 'success', nil
      # it_behaves_like 'ToNG', 422, nil, false
      it_behaves_like 'ToMsg', nil, 'devise_token_auth.registrations.account_with_uid_destroyed', nil, nil
      # it_behaves_like 'ToMsg', nil, nil, 'alert.user.destroy_reserved', nil
    end
  end
end
