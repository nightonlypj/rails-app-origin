require 'rails_helper'

RSpec.describe 'Users::Auth::Registrations', type: :request do
  # POST /users/auth/sign_up アカウント登録(処理)
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  #   パラメータなし, 有効なパラメータ, 無効なパラメータ, ホワイトリストにないURL → 事前にデータ作成
  describe 'POST #create' do
    let!(:new_user) { FactoryBot.attributes_for(:user) }
    let!(:valid_params) do
      {
        name: new_user[:name],
        email: new_user[:email],
        password: new_user[:password],
        confirm_success_url: "#{FRONT_SITE_URL}sign_in"
      }
    end
    let!(:invalid_params) do
      {
        name: new_user[:name],
        email: nil,
        password: new_user[:password],
        confirm_success_url: "#{FRONT_SITE_URL}sign_in"
      }
    end
    let!(:invalid_url_params) do
      {
        name: new_user[:name],
        email: new_user[:email],
        password: new_user[:password],
        confirm_success_url: "#{BAD_SITE_URL}sign_in"
      }
    end

    # テスト内容
    shared_examples_for 'OK' do
      it '作成・メールが送信される' do
        expect do
          before_count = ActionMailer::Base.deliveries.count
          post create_user_auth_registration_path, params: params, headers: headers
          expect(ActionMailer::Base.deliveries.count).to eq(before_count + 1) # メールアドレス確認のお願い

          after_user = User.find_by(email: new_user[:email])
          expect(after_user).not_to be_nil
          expect(after_user.name).to eq(new_user[:name])
        end.to change(User, :count).by(1)
      end
    end
    shared_examples_for 'NG' do
      it '作成・メールが送信されない' do
        expect do
          before_count = ActionMailer::Base.deliveries.count
          post create_user_auth_registration_path, params: params, headers: headers
          expect(ActionMailer::Base.deliveries.count).to eq(before_count)
        end.to change(User, :count).by(0)
      end
    end

    shared_examples_for 'ToOK' do # |alert, notice|
      it '成功ステータス・JSONデータ' do
        post create_user_auth_registration_path, params: params, headers: headers
        expect(response).to be_successful

        response_json = JSON.parse(response.body)
        expect(response_json['status']).to eq('success')
        # expect(response_json['status']).to be_nil
        # expect(response_json['success']).to eq(true)
        expect(response_json['errors']).to be_nil
        # expect(response_json['data']['id']).to be_nil
        expect(response_json['data']['name']).to eq(params[:name])

        # expect(response_json['alert']).to alert.present? ? eq(I18n.t(alert)) : be_nil
        # expect(response_json['notice']).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end
    shared_examples_for 'ToNG' do # |alert, notice|
      it '失敗ステータス・JSONデータ' do
        post create_user_auth_registration_path, params: params, headers: headers
        expect(response).to have_http_status(422)

        response_json = JSON.parse(response.body)
        expect(response_json['status']).to eq('error')
        # expect(response_json['status']).to be_nil
        # expect(response_json['success']).to eq(false)
        expect(response_json['errors']).not_to be_nil
        # expect(response_json['data']).not_to be_nil # Tips: パラメータなしの場合はnil
        # expect(response_json['data']).to be_nil

        # expect(response_json['alert']).to alert.present? ? eq(I18n.t(alert)) : be_nil
        # expect(response_json['notice']).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end

    # テストケース
    shared_examples_for '[*]パラメータなし' do
      let!(:params) { nil }
      it_behaves_like 'NG'
      it_behaves_like 'ToNG', nil, nil
    end
    shared_examples_for '[未ログイン]有効なパラメータ' do
      let!(:params) { valid_params }
      it_behaves_like 'OK'
      it_behaves_like 'ToOK', nil, 'devise.registrations.signed_up_but_unconfirmed'
    end
    shared_examples_for '[ログイン中/削除予約済み]有効なパラメータ' do
      let!(:params) { valid_params }
      it_behaves_like 'OK'
      it_behaves_like 'ToOK', nil, nil
      # it_behaves_like 'NG'
      # it_behaves_like 'ToNG', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン]無効なパラメータ' do
      let!(:params) { invalid_params }
      it_behaves_like 'NG'
      it_behaves_like 'ToNG', nil, nil
    end
    shared_examples_for '[ログイン中/削除予約済み]無効なパラメータ' do
      let!(:params) { invalid_params }
      it_behaves_like 'NG'
      it_behaves_like 'ToNG', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[*]ホワイトリストにないURL' do
      let!(:params) { invalid_url_params }
      it_behaves_like 'NG'
      it_behaves_like 'ToNG', nil, nil
    end

    context '未ログイン' do
      let!(:headers) { nil }
      it_behaves_like '[*]パラメータなし'
      it_behaves_like '[未ログイン]有効なパラメータ'
      it_behaves_like '[未ログイン]無効なパラメータ'
      it_behaves_like '[*]ホワイトリストにないURL'
    end
    context 'ログイン中' do
      include_context 'authログイン処理'
      let!(:headers) { auth_headers }
      it_behaves_like '[*]パラメータなし'
      it_behaves_like '[ログイン中/削除予約済み]有効なパラメータ'
      it_behaves_like '[ログイン中/削除予約済み]無効なパラメータ'
      it_behaves_like '[*]ホワイトリストにないURL'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'authログイン処理', true
      let!(:headers) { auth_headers }
      it_behaves_like '[*]パラメータなし'
      it_behaves_like '[ログイン中/削除予約済み]有効なパラメータ'
      it_behaves_like '[ログイン中/削除予約済み]無効なパラメータ'
      it_behaves_like '[*]ホワイトリストにないURL'
    end
  end

  # PUT(PATCH) /users/auth/update 登録情報変更(処理)
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  #   パラメータなし, 有効なパラメータ, 無効なパラメータ → 事前にデータ作成
  describe 'PUT #update' do
    let!(:valid_params) { FactoryBot.attributes_for(:user) }
    let!(:invalid_params) { FactoryBot.attributes_for(:user, email: nil) }

    # テスト内容
    shared_examples_for 'OK' do
      it '確認待ちメールアドレス・氏名が変更される' do
        put update_user_auth_registration_path, params: params, headers: headers
        after_user = User.find(user.id)
        expect(after_user.unconfirmed_email).to eq(params[:email])
        expect(after_user.name).to eq(params[:name])
      end
      it 'メールが送信される' do
        before_count = ActionMailer::Base.deliveries.count
        put update_user_auth_registration_path, params: params, headers: headers
        expect(ActionMailer::Base.deliveries.count).to eq(before_count + 3) # メールアドレス変更受け付けのお知らせ、パスワード変更完了のお知らせ、メールアドレス確認のお願い
      end
    end
    shared_examples_for 'NG' do
      it '確認待ちメールアドレス・氏名が変更されない' do
        put update_user_auth_registration_path, params: params, headers: headers
        after_user = User.find(user.id)
        expect(after_user.unconfirmed_email).to eq(user.unconfirmed_email)
        expect(after_user.name).to eq(user.name)
      end
      it 'メールが送信されない' do
        before_count = ActionMailer::Base.deliveries.count
        put update_user_auth_registration_path, params: params, headers: headers
        expect(ActionMailer::Base.deliveries.count).to eq(before_count)
      end
    end

    shared_examples_for 'ToOK' do # |alert, notice|
      it '成功ステータス・JSONデータ' do
        put update_user_auth_registration_path, params: params, headers: headers
        expect(response).to be_successful

        response_json = JSON.parse(response.body)
        expect(response_json['status']).to eq('success')
        # expect(response_json['status']).to be_nil
        # expect(response_json['success']).to eq(true)
        expect(response_json['errors']).to be_nil
        # expect(response_json['data']['id']).to be_nil
        expect(response_json['data']['name']).to eq(params[:name])

        # expect(response_json['alert']).to alert.present? ? eq(I18n.t(alert)) : be_nil
        # expect(response_json['notice']).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end
    shared_examples_for 'ToNG' do # |alert, notice|
      it '失敗ステータス・JSONデータ' do
        put update_user_auth_registration_path, params: params, headers: headers
        expect(response).to have_http_status(422)

        response_json = JSON.parse(response.body)
        expect(response_json['status']).to eq('error')
        # expect(response_json['status']).to be_nil
        # expect(response_json['success']).to eq(false)
        expect(response_json['errors']).not_to be_nil
        expect(response_json['data']).to be_nil

        # expect(response_json['alert']).to alert.present? ? eq(I18n.t(alert)) : be_nil
        # expect(response_json['notice']).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end
    shared_examples_for 'ToNG(404)' do
      it '失敗ステータス・JSONデータ' do
        put update_user_auth_registration_path, params: params, headers: headers
        expect(response).to have_http_status(404)

        response_json = JSON.parse(response.body)
        expect(response_json['status']).to eq('error')
        expect(response_json['errors']).not_to be_nil
      end
    end

    # テストケース
    shared_examples_for '[未ログイン]パラメータなし' do
      let!(:params) { nil }
      # it_behaves_like 'NG' # Tips: 未ログインの為、対象がない
      it_behaves_like 'ToNG', nil, nil
    end
    shared_examples_for '[ログイン中/削除予約済み]パラメータなし' do
      let!(:params) { nil }
      it_behaves_like 'NG'
      it_behaves_like 'ToNG', nil, nil
    end
    shared_examples_for '[未ログイン]有効なパラメータ' do
      let!(:params) { valid_params }
      # it_behaves_like 'NG' # Tips: 未ログインの為、対象がない
      it_behaves_like 'ToNG(404)'
      # it_behaves_like 'ToNG', 'devise.failure.unauthenticated', nil
    end
    shared_examples_for '[ログイン中]有効なパラメータ' do
      let!(:params) { valid_params }
      it_behaves_like 'OK'
      it_behaves_like 'ToOK', nil, 'devise.registrations.update_needs_confirmation'
    end
    shared_examples_for '[削除予約済み]有効なパラメータ' do
      let!(:params) { valid_params }
      it_behaves_like 'OK'
      it_behaves_like 'ToOK', nil, nil
      # it_behaves_like 'NG'
      # it_behaves_like 'ToNG', 'alert.user.destroy_reserved', nil
    end
    shared_examples_for '[未ログイン]無効なパラメータ' do
      let!(:params) { invalid_params }
      # it_behaves_like 'NG' # Tips: 未ログインの為、対象がない
      it_behaves_like 'ToNG(404)'
      # it_behaves_like 'ToNG', 'devise.failure.unauthenticated', nil
    end
    shared_examples_for '[ログイン中]無効なパラメータ' do
      let!(:params) { invalid_params }
      it_behaves_like 'NG'
      it_behaves_like 'ToNG', nil, nil
    end
    shared_examples_for '[削除予約済み]無効なパラメータ' do
      let!(:params) { invalid_params }
      it_behaves_like 'NG'
      it_behaves_like 'ToNG', 'alert.user.destroy_reserved', nil
    end

    context '未ログイン' do
      let!(:headers) { nil }
      it_behaves_like '[未ログイン]パラメータなし'
      it_behaves_like '[未ログイン]有効なパラメータ'
      it_behaves_like '[未ログイン]無効なパラメータ'
    end
    context 'ログイン中' do
      include_context 'authログイン処理'
      let!(:headers) { auth_headers }
      include_context '画像登録処理'
      it_behaves_like '[ログイン中/削除予約済み]パラメータなし'
      it_behaves_like '[ログイン中]有効なパラメータ'
      it_behaves_like '[ログイン中]無効なパラメータ'
      include_context '画像削除処理'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'authログイン処理', true
      let!(:headers) { auth_headers }
      include_context '画像登録処理'
      it_behaves_like '[ログイン中/削除予約済み]パラメータなし'
      it_behaves_like '[削除予約済み]有効なパラメータ'
      it_behaves_like '[削除予約済み]無効なパラメータ'
      include_context '画像削除処理'
    end
  end

  # DELETE /users/auth/destroy アカウント削除(処理)
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  describe 'DELETE #destroy' do
    # テスト内容
    shared_examples_for 'OK' do
      it '削除される' do
        expect do
          delete destroy_user_auth_registration_path, headers: headers
        end.to change(User, :count).by(-1)
      end
      # let!(:start_time) { Time.current - 1.second }
      # it '削除依頼日時が現在日時に変更される' do
      #   delete destroy_user_auth_registration_path, headers: headers
      #   expect(user.destroy_requested_at).to be_between(start_time, Time.current)
      # end
      # it "削除予定日時が#{Settings['destroy_schedule_days']}日後に変更される" do
      #   delete destroy_user_auth_registration_path, headers: headers
      #   expect(user.destroy_schedule_at).to be_between(start_time + Settings['destroy_schedule_days'].days,
      #                                                  Time.current + Settings['destroy_schedule_days'].days)
      # end
    end
    shared_examples_for 'NG' do
      it '削除されない' do
        expect do
          delete destroy_user_auth_registration_path, headers: headers
        end.to change(User, :count).by(0)
      end
      # let!(:before_user) { user }
      # it '削除依頼日時が変更されない' do
      #   delete destroy_user_auth_registration_path, headers: headers
      #   expect(user.destroy_requested_at).to eq(before_user.destroy_requested_at)
      # end
      # it '削除予定日時が変更されない' do
      #   delete destroy_user_auth_registration_path, headers: headers
      #   expect(user.destroy_schedule_at).to eq(before_user.destroy_schedule_at)
      # end
    end

    shared_examples_for 'ToOK' do # |alert, notice|
      it '成功ステータス・JSONデータ' do
        delete destroy_user_auth_registration_path, headers: headers
        expect(response).to be_successful

        response_json = JSON.parse(response.body)
        expect(response_json['status']).to eq('success')
        # expect(response_json['status']).to be_nil
        # expect(response_json['success']).to eq(true)
        expect(response_json['errors']).to be_nil
        expect(response_json['message']).not_to be_nil
        # expect(response_json['message']).to be_nil

        # expect(response_json['alert']).to alert.present? ? eq(I18n.t(alert)) : be_nil
        # expect(response_json['notice']).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end
    shared_examples_for 'ToNG' do # |alert, notice|
      it '失敗ステータス・JSONデータ' do
        delete destroy_user_auth_registration_path, headers: headers
        expect(response).to have_http_status(422)

        response_json = JSON.parse(response.body)
        expect(response_json['status']).to eq('error')
        # expect(response_json['status']).to be_nil
        # expect(response_json['success']).to eq(false)
        expect(response_json['errors']).not_to be_nil
        expect(response_json['message']).to be_nil

        # expect(response_json['alert']).to alert.present? ? eq(I18n.t(alert)) : be_nil
        # expect(response_json['notice']).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end
    shared_examples_for 'ToNG(404)' do
      it '失敗ステータス・JSONデータ' do
        delete destroy_user_auth_registration_path, headers: headers
        expect(response).to have_http_status(404)

        response_json = JSON.parse(response.body)
        expect(response_json['status']).to eq('error')
        expect(response_json['errors']).not_to be_nil
        expect(response_json['message']).to be_nil
      end
    end

    # テストケース
    context '未ログイン' do
      let!(:headers) { nil }
      it_behaves_like 'NG'
      # it_behaves_like 'NG' # Tips: 未ログインの為、対象がない
      it_behaves_like 'ToNG(404)'
      # it_behaves_like 'ToNG', 'devise.failure.unauthenticated', nil
    end
    context 'ログイン中' do
      include_context 'authログイン処理'
      let!(:headers) { auth_headers }
      it_behaves_like 'OK'
      it_behaves_like 'ToOK', nil, 'devise.registrations.destroy_reserved'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'authログイン処理', true
      let!(:headers) { auth_headers }
      it_behaves_like 'OK'
      it_behaves_like 'ToOK', nil, nil
      # it_behaves_like 'NG'
      # it_behaves_like 'ToNG', 'alert.user.destroy_reserved', nil
    end
  end
end
