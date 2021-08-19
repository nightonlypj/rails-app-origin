require 'rails_helper'

RSpec.describe 'Users::Auth::Confirmations', type: :request do
  # POST /users/auth/confirmation メールアドレス確認[メール再送](処理)
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  #   パラメータなし, 有効なパラメータ, 無効なパラメータ, ホワイトリストにないURL → 事前にデータ作成
  describe 'POST #create' do
    let!(:send_user) { FactoryBot.create(:user, confirmed_at: nil) }
    let!(:valid_params) { { email: send_user.email, confirm_success_url: "#{FRONT_SITE_URL}sign_in" } }
    let!(:invalid_params) { { email: nil, confirm_success_url: "#{FRONT_SITE_URL}sign_in" } }
    let!(:invalid_url_params) { { email: send_user.email, confirm_success_url: "#{BAD_SITE_URL}sign_in" } }

    # テスト内容
    shared_examples_for 'OK' do
      it 'メールが送信される' do
        before_count = ActionMailer::Base.deliveries.count
        post create_user_auth_confirmation_path, params: params, headers: headers
        expect(ActionMailer::Base.deliveries.count).to eq(before_count + 1) # メールアドレス確認のお願い
      end
    end
    shared_examples_for 'NG' do
      it 'メールが送信されない' do
        before_count = ActionMailer::Base.deliveries.count
        post create_user_auth_registration_path, params: params, headers: headers
        expect(ActionMailer::Base.deliveries.count).to eq(before_count)
      end
    end

    shared_examples_for 'ToOK' do # |alert, notice|
      it '成功ステータス・JSONデータ' do
        post create_user_auth_confirmation_path, params: params, headers: headers
        expect(response).to be_successful

        response_json = JSON.parse(response.body)
        expect(response_json['success']).to eq(true)
        expect(response_json['errors']).to be_nil
        expect(response_json['message']).not_to be_nil
        # expect(response_json['message']).to be_nil

        # expect(response_json['alert']).to alert.present? ? eq(I18n.t(alert)) : be_nil
        # expect(response_json['notice']).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end
    shared_examples_for 'ToNG' do # |alert, notice|
      it '失敗ステータス・JSONデータ' do
        post create_user_auth_confirmation_path, params: params, headers: headers
        expect(response).to have_http_status(401)
        # expect(response).to have_http_status(422)

        response_json = JSON.parse(response.body)
        expect(response_json['success']).to eq(false)
        expect(response_json['errors']).not_to be_nil
        expect(response_json['message']).to be_nil

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
    shared_examples_for '[*]有効なパラメータ' do # Tips: ログイン中も出来ても良さそう
      let!(:params) { valid_params }
      it_behaves_like 'OK'
      it_behaves_like 'ToOK', nil, 'devise.confirmations.send_instructions'
    end
    shared_examples_for '[*]無効なパラメータ' do
      let!(:params) { invalid_params }
      it_behaves_like 'NG'
      it_behaves_like 'ToNG', nil, nil
    end
    shared_examples_for '[*]ホワイトリストにないURL' do
      let!(:params) { invalid_url_params }
      it_behaves_like 'OK'
      it_behaves_like 'ToOK', nil, nil
      # it_behaves_like 'NG'
      # it_behaves_like 'ToNG', nil, nil
    end

    context '未ログイン' do
      let!(:headers) { nil }
      it_behaves_like '[*]パラメータなし'
      it_behaves_like '[*]有効なパラメータ'
      it_behaves_like '[*]無効なパラメータ'
      it_behaves_like '[*]ホワイトリストにないURL'
    end
    context 'ログイン中' do
      include_context 'authログイン処理'
      let!(:headers) { auth_headers }
      it_behaves_like '[*]パラメータなし'
      it_behaves_like '[*]有効なパラメータ'
      it_behaves_like '[*]無効なパラメータ'
      it_behaves_like '[*]ホワイトリストにないURL'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'authログイン処理', true
      let!(:headers) { auth_headers }
      it_behaves_like '[*]パラメータなし'
      it_behaves_like '[*]有効なパラメータ'
      it_behaves_like '[*]無効なパラメータ'
      it_behaves_like '[*]ホワイトリストにないURL'
    end
  end

  # GET /users/auth/confirmation メールアドレス確認(処理)
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  #   トークン: 期限内, 期限切れ, 存在しない, ない → データ作成
  #   確認日時: ない（未確認）, 確認送信日時より前（未確認）, 確認送信日時より後（確認済み） → データ作成
  #   ＋リダイレクトURL: ある, ない, ホワイトリストにない
  describe 'GET #show' do
    let!(:valid_redirect_url) { "#{FRONT_SITE_URL}sign_in" }
    let!(:invalid_redirect_url) { "#{BAD_SITE_URL}sign_in" }

    # テスト内容
    shared_examples_for 'OK' do
      let!(:start_time) { Time.now.utc - 1.second }
      it '[リダイレクトURLがある]確認日時が現在日時に変更される' do
        get user_auth_confirmation_path(confirmation_token: confirmation_token, redirect_url: valid_redirect_url)
        expect(User.find(@send_user.id).confirmed_at).to be_between(start_time, Time.now.utc)
      end
      it '[リダイレクトURLがない]確認日時が現在日時に変更される' do
        get user_auth_confirmation_path(confirmation_token: confirmation_token, redirect_url: nil)
        expect(User.find(@send_user.id).confirmed_at).to be_between(start_time, Time.now.utc)
      end
      it '[リダイレクトURLがホワイトリストにない]確認日時が現在日時に変更される' do
        get user_auth_confirmation_path(confirmation_token: confirmation_token, redirect_url: invalid_redirect_url)
        expect(User.find(@send_user.id).confirmed_at).to be_between(start_time, Time.now.utc)
      end
    end
    shared_examples_for 'NG' do
      it '[リダイレクトURLがある]確認日時が変更されない' do
        get user_auth_confirmation_path(confirmation_token: confirmation_token, redirect_url: valid_redirect_url)
        expect(User.find(@send_user.id).confirmed_at).to eq(@send_user.confirmed_at)
      end
      it '[リダイレクトURLがない]確認日時が変更されない' do
        get user_auth_confirmation_path(confirmation_token: confirmation_token, redirect_url: nil)
        expect(User.find(@send_user.id).confirmed_at).to eq(@send_user.confirmed_at)
      end
      it '[リダイレクトURLがホワイトリストにない]確認日時が変更されない' do
        get user_auth_confirmation_path(confirmation_token: confirmation_token, redirect_url: invalid_redirect_url)
        expect(User.find(@send_user.id).confirmed_at).to eq(@send_user.confirmed_at)
      end
    end

    shared_examples_for 'ToOK' do # |alert, notice|
      it '[リダイレクトURLがある]指定URL（成功パラメータ）にリダイレクト' do
        get user_auth_confirmation_path(confirmation_token: confirmation_token, redirect_url: valid_redirect_url)
        expect(response).to redirect_to(/^#{valid_redirect_url}\?.*account_confirmation_success=true.*$/) # Tips: ログイン中はaccess-token等も入る
        # param = '?account_confirmation_success=true'
        # param += "&alert=#{I18n.t(alert)}" if alert.present?
        # param += "&notice=#{I18n.t(notice)}" if notice.present?
        # expect(response).to redirect_to("#{valid_redirect_url}#{param}")
      end
      it '[リダイレクトURLがない]成功ページにリダイレクト' do
        get user_auth_confirmation_path(confirmation_token: confirmation_token, redirect_url: nil)
        not_redirect_url = 'http://www.example.com://'
        expect(response).to redirect_to(/^#{not_redirect_url}\?.*account_confirmation_success=true.*$/) # Tips: ログイン中はaccess-token等も入る
        # expect(response).to redirect_to('/confirmation_success.html?not')
      end
      it '[リダイレクトURLがホワイトリストにない]成功ページにリダイレクト' do
        get user_auth_confirmation_path(confirmation_token: confirmation_token, redirect_url: invalid_redirect_url)
        expect(response).to redirect_to(/^#{invalid_redirect_url}\?.*account_confirmation_success=true.*$/) # Tips: ログイン中はaccess-token等も入る
        # expect(response).to redirect_to('/confirmation_success.html?bad')
      end
    end
    shared_examples_for 'ToNG' do |alert, notice|
      it '[リダイレクトURLがある]指定URL（失敗パラメータ）にリダイレクト' do
        get user_auth_confirmation_path(confirmation_token: confirmation_token, redirect_url: valid_redirect_url)
        param = '?account_confirmation_success=false'
        param += "&alert=#{I18n.t(alert)}" if alert.present?
        param += "&notice=#{I18n.t(notice)}" if notice.present?
        expect(response).to redirect_to("#{valid_redirect_url}#{param}")
      end
      it '[リダイレクトURLがない]エラーページにリダイレクト' do
        get user_auth_confirmation_path(confirmation_token: confirmation_token, redirect_url: nil)
        not_redirect_url = 'http://www.example.com://'
        expect(response).to redirect_to(/^#{not_redirect_url}\?.*account_confirmation_success=true.*$/) # Tips: ログイン中はaccess-token等も入る
        # expect(response).to redirect_to('/confirmation_error.html?not')
      end
      it '[リダイレクトURLがホワイトリストにない]エラーページにリダイレクト' do
        get user_auth_confirmation_path(confirmation_token: confirmation_token, redirect_url: invalid_redirect_url)
        expect(response).to redirect_to(/^#{invalid_redirect_url}\?.*account_confirmation_success=true.*$/) # Tips: ログイン中はaccess-token等も入る
        # expect(response).to redirect_to('/confirmation_error.html?bad')
      end
    end

    # テストケース
    shared_examples_for '[未ログイン][期限内]確認日時がない（未確認）' do
      it_behaves_like 'OK'
      it_behaves_like 'ToOK', nil, 'devise.confirmations.confirmed'
    end
    shared_examples_for '[ログイン中/削除予約済み][期限内]確認日時がない（未確認）' do # Tips: ログイン中も出来ても良さそう
      it_behaves_like 'OK'
      it_behaves_like 'ToOK', nil, 'devise.confirmations.confirmed'
    end
    shared_examples_for '[*][期限切れ]確認日時がない（未確認）' do
      # Tips: ActionController::RoutingError: Not Found
      # it_behaves_like 'NG'
      # it_behaves_like 'ToNG', 'activerecord.errors.models.user.attributes.confirmation_token.invalid', nil
    end
    shared_examples_for '[*][存在しない/ない]確認日時がない（未確認）' do
      # Tips: ActionController::RoutingError: Not Found
      # it_behaves_like 'NG' # Tips: トークンが存在しない為、確認日時がない
      # it_behaves_like 'ToNG', 'activerecord.errors.models.user.attributes.confirmation_token.invalid', nil
    end
    shared_examples_for '[未ログイン][期限内]確認日時が確認送信日時より前（未確認）' do
      include_context 'メールアドレス確認トークン確認', true
      it_behaves_like 'OK'
      it_behaves_like 'ToOK', nil, 'devise.confirmations.confirmed'
    end
    shared_examples_for '[ログイン中/削除予約済み][期限内]確認日時が確認送信日時より前（未確認）' do # Tips: ログイン中も出来ても良さそう
      include_context 'メールアドレス確認トークン確認', true
      it_behaves_like 'OK'
      it_behaves_like 'ToOK', nil, 'devise.confirmations.confirmed'
    end
    shared_examples_for '[*][期限切れ]確認日時が確認送信日時より前（未確認）' do
      include_context 'メールアドレス確認トークン確認', true
      # Tips: ActionController::RoutingError: Not Found
      # it_behaves_like 'NG'
      # it_behaves_like 'ToNG', 'activerecord.errors.models.user.attributes.confirmation_token.invalid', nil
    end
    shared_examples_for '[*][期限内]確認日時が確認送信日時より後（確認済み）' do
      include_context 'メールアドレス確認トークン確認', false
      it_behaves_like 'OK'
      it_behaves_like 'ToOK'
      # it_behaves_like 'NG'
      # it_behaves_like 'ToNG', 'errors.messages.already_confirmed', nil
    end
    shared_examples_for '[*][期限切れ]確認日時が確認送信日時より後（確認済み）' do
      include_context 'メールアドレス確認トークン確認', false
      # Tips: ActionController::RoutingError: Not Found
      # it_behaves_like 'NG'
      # it_behaves_like 'ToNG', 'activerecord.errors.models.user.attributes.confirmation_token.invalid', nil
    end

    shared_examples_for '[未ログイン]トークンが期限内' do
      include_context 'メールアドレス確認トークン作成', true
      it_behaves_like '[未ログイン][期限内]確認日時がない（未確認）'
      it_behaves_like '[未ログイン][期限内]確認日時が確認送信日時より前（未確認）'
      it_behaves_like '[*][期限内]確認日時が確認送信日時より後（確認済み）'
    end
    shared_examples_for '[ログイン中/削除予約済み]トークンが期限内' do
      include_context 'メールアドレス確認トークン作成', true
      it_behaves_like '[ログイン中/削除予約済み][期限内]確認日時がない（未確認）'
      it_behaves_like '[ログイン中/削除予約済み][期限内]確認日時が確認送信日時より前（未確認）'
      it_behaves_like '[*][期限内]確認日時が確認送信日時より後（確認済み）'
    end
    shared_examples_for '[*]トークンが期限切れ' do
      include_context 'メールアドレス確認トークン作成', false
      it_behaves_like '[*][期限切れ]確認日時がない（未確認）'
      it_behaves_like '[*][期限切れ]確認日時が確認送信日時より前（未確認）'
      it_behaves_like '[*][期限切れ]確認日時が確認送信日時より後（確認済み）'
    end
    shared_examples_for '[*]トークンが存在しない' do
      let!(:confirmation_token) { NOT_TOKEN }
      it_behaves_like '[*][存在しない/ない]確認日時がない（未確認）'
      # it_behaves_like '[*][存在しない]確認日時が確認送信日時より前（未確認）' # Tips: トークンが存在しない為、確認日時がない
      # it_behaves_like '[*][存在しない]確認日時が確認送信日時より後（確認済み）' # Tips: トークンが存在しない為、確認日時がない
    end
    shared_examples_for '[*]トークンがない' do
      let!(:confirmation_token) { NO_TOKEN }
      it_behaves_like '[*][存在しない/ない]確認日時がない（未確認）'
      # it_behaves_like '[*][ない]確認日時が確認送信日時より前（未確認）' # Tips: トークンが存在しない為、確認日時がない
      # it_behaves_like '[*][ない]確認日時が確認送信日時より後（確認済み）' # Tips: トークンが存在しない為、確認日時がない
    end

    context '未ログイン' do
      it_behaves_like '[未ログイン]トークンが期限内'
      it_behaves_like '[*]トークンが期限切れ'
      it_behaves_like '[*]トークンが存在しない'
      it_behaves_like '[*]トークンがない'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[ログイン中/削除予約済み]トークンが期限内'
      it_behaves_like '[*]トークンが期限切れ'
      it_behaves_like '[*]トークンが存在しない'
      it_behaves_like '[*]トークンがない'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it_behaves_like '[ログイン中/削除予約済み]トークンが期限内'
      it_behaves_like '[*]トークンが期限切れ'
      it_behaves_like '[*]トークンが存在しない'
      it_behaves_like '[*]トークンがない'
    end
  end
end
