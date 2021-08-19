require 'rails_helper'

RSpec.describe 'Users::Auth::Unlocks', type: :request do
  # POST /users/auth/unlock アカウントロック解除[メール再送](処理)
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  #   パラメータなし, 有効なパラメータ, 無効なパラメータ, ホワイトリストにないURL → 事前にデータ作成
  describe 'POST #create' do
    include_context 'アカウントロック解除トークン作成'
    let!(:send_user) { FactoryBot.create(:user) }
    let!(:valid_params) { { email: send_user.email, redirect_url: "#{FRONT_SITE_URL}sign_in" } }
    let!(:invalid_params) { { email: nil, redirect_url: "#{FRONT_SITE_URL}sign_in" } }
    let!(:invalid_url_params) { { email: send_user.email, redirect_url: BAD_SITE_URL } }

    # テスト内容
    shared_examples_for 'OK' do
      it 'メールが送信される' do
        before_count = ActionMailer::Base.deliveries.count
        post create_user_auth_unlock_path, params: params, headers: headers
        expect(ActionMailer::Base.deliveries.count).to eq(before_count + 1) # アカウントロックのお知らせ
      end
    end
    shared_examples_for 'NG' do
      it 'メールが送信されない' do
        before_count = ActionMailer::Base.deliveries.count
        post create_user_auth_unlock_path, params: params, headers: headers
        expect(ActionMailer::Base.deliveries.count).to eq(before_count)
      end
    end

    shared_examples_for 'ToOK' do # |alert, notice|
      it '成功ステータス・JSONデータ' do
        post create_user_auth_unlock_path, params: params, headers: headers
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
    shared_examples_for 'ToNG' do |alert, notice|
      it '失敗ステータス・JSONデータ' do
        post create_user_auth_unlock_path, params: params, headers: headers
        expect(response).to have_http_status(422)

        response_json = JSON.parse(response.body)
        expect(response_json['success']).to eq(false)
        expect(response_json['errors']).not_to be_nil
        expect(response_json['message']).to be_nil

        expect(response_json['alert']).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(response_json['notice']).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end
    shared_examples_for 'ToNG(401)' do
      it '失敗ステータス・JSONデータ' do
        post create_user_auth_unlock_path, params: params, headers: headers
        expect(response).to have_http_status(401)

        response_json = JSON.parse(response.body)
        expect(response_json['success']).to eq(false)
        expect(response_json['errors']).not_to be_nil
        expect(response_json['message']).to be_nil
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
      it_behaves_like 'ToOK', nil, 'devise.unlocks.send_instructions'
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
      it_behaves_like 'ToNG(401)'
      # it_behaves_like 'ToNG', nil, nil
    end
    shared_examples_for '[ログイン中/削除予約済み]無効なパラメータ' do
      let!(:params) { invalid_params }
      it_behaves_like 'NG'
      it_behaves_like 'ToNG(401)'
      # it_behaves_like 'ToNG', 'devise.failure.already_authenticated', nil
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

  # GET /users/auth/unlock アカウントロック解除(処理)
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  #   トークン: 存在する, 存在しない, ない → データ作成
  #   ロック日時: ない（未ロック）, ある（ロック中） → データ作成
  #   ＋リダイレクトURL: ある, ない, ホワイトリストにない
  describe 'GET #show' do
    let!(:valid_redirect_url) { "#{FRONT_SITE_URL}sign_in" }
    let!(:invalid_redirect_url) { "#{BAD_SITE_URL}sign_in" }

    # テスト内容
    shared_examples_for 'OK' do
      it '[リダイレクトURLがある]アカウントロック日時がなしに変更される' do
        get user_auth_unlock_path(unlock_token: unlock_token, redirect_url: valid_redirect_url)
        expect(User.find(@send_user.id).locked_at).to be_nil
      end
      it '[リダイレクトURLがない]アカウントロック日時がなしに変更される' do
        get user_auth_unlock_path(unlock_token: unlock_token, redirect_url: nil)
        expect(User.find(@send_user.id).locked_at).to eq(@send_user.locked_at)
        # expect(User.find(@send_user.id).locked_at).to be_nil
      end
      it '[リダイレクトURLがホワイトリストにない]アカウントロック日時がなしに変更される' do
        get user_auth_unlock_path(unlock_token: unlock_token, redirect_url: invalid_redirect_url)
        expect(User.find(@send_user.id).locked_at).to eq(@send_user.locked_at)
        # expect(User.find(@send_user.id).locked_at).to be_nil
      end
    end
    shared_examples_for 'NG' do
      it '[リダイレクトURLがある]アカウントロック日時が変更されない' do
        get user_auth_unlock_path(unlock_token: unlock_token, redirect_url: valid_redirect_url)
        expect(User.find(@send_user.id).locked_at).to eq(@send_user.locked_at)
      end
      it '[リダイレクトURLがない]アカウントロック日時が変更されない' do
        get user_auth_unlock_path(unlock_token: unlock_token, redirect_url: nil)
        expect(User.find(@send_user.id).locked_at).to eq(@send_user.locked_at)
      end
      it '[リダイレクトURLがホワイトリストにない]アカウントロック日時が変更されない' do
        get user_auth_unlock_path(unlock_token: unlock_token, redirect_url: invalid_redirect_url)
        expect(User.find(@send_user.id).locked_at).to eq(@send_user.locked_at)
      end
    end

    shared_examples_for 'ToOK' do # |alert, notice|
      it '[リダイレクトURLがある]指定URL（成功パラメータ）にリダイレクト' do
        get user_auth_unlock_path(unlock_token: unlock_token, redirect_url: valid_redirect_url)
        param = '?unlock=true'
        # param += "&alert=#{I18n.t(alert)}" if alert.present?
        # param += "&notice=#{I18n.t(notice)}" if notice.present?
        expect(response).to redirect_to("#{valid_redirect_url}#{param}")
      end
      it '[リダイレクトURLがない]成功ページにリダイレクト' do
        get user_auth_unlock_path(unlock_token: unlock_token, redirect_url: nil)
        expect(response).to have_http_status(422)
        response_json = JSON.parse(response.body)
        expect(response_json['success']).to eq(false)
        expect(response_json['errors']).not_to be_nil
        expect(response_json['message']).to be_nil
        # expect(response).to redirect_to('/unlock_success.html?not')
      end
      it '[リダイレクトURLがホワイトリストにない]成功ページにリダイレクト' do
        get user_auth_unlock_path(unlock_token: unlock_token, redirect_url: invalid_redirect_url)
        expect(response).to have_http_status(422)
        response_json = JSON.parse(response.body)
        expect(response_json['success']).to eq(false)
        expect(response_json['errors']).not_to be_nil
        expect(response_json['message']).to be_nil
        # expect(response).to redirect_to('/unlock_success.html?bad')
      end
    end
    shared_examples_for 'ToNG' do |alert, notice|
      it '[リダイレクトURLがある]指定URL（失敗パラメータ）にリダイレクト' do
        get user_auth_unlock_path(unlock_token: unlock_token, redirect_url: valid_redirect_url)
        param = '?unlock=false'
        param += "&alert=#{I18n.t(alert)}" if alert.present?
        param += "&notice=#{I18n.t(notice)}" if notice.present?
        expect(response).to redirect_to("#{valid_redirect_url}#{param}")
      end
      it '[リダイレクトURLがない]エラーページにリダイレクト' do
        get user_auth_unlock_path(unlock_token: unlock_token, redirect_url: nil)
        expect(response).to have_http_status(422)
        response_json = JSON.parse(response.body)
        expect(response_json['success']).to eq(false)
        expect(response_json['errors']).not_to be_nil
        expect(response_json['message']).to be_nil
        # expect(response).to redirect_to('/unlock_error.html?not')
      end
      it '[リダイレクトURLがホワイトリストにない]エラーページにリダイレクト' do
        get user_auth_unlock_path(unlock_token: unlock_token, redirect_url: invalid_redirect_url)
        expect(response).to have_http_status(422)
        response_json = JSON.parse(response.body)
        expect(response_json['success']).to eq(false)
        expect(response_json['errors']).not_to be_nil
        expect(response_json['message']).to be_nil
        # expect(response).to redirect_to('/unlock_error.html?bad')
      end
    end

    # テストケース
    shared_examples_for '[未ログイン][存在する]ロック日時がない（未ロック）' do
      include_context 'アカウントロック解除トークン解除'
      # it_behaves_like 'NG' # Tips: 元々、ロック日時がない
      it_behaves_like 'ToOK', nil, nil
      # it_behaves_like 'ToNG', nil, 'devise.unlocks.unlocked' # Tips: 既に解除済み
    end
    shared_examples_for '[ログイン中/削除予約済み][存在する]ロック日時がない（未ロック）' do
      include_context 'アカウントロック解除トークン解除'
      # it_behaves_like 'NG' # Tips: 元々、ロック日時がない
      it_behaves_like 'ToOK', nil, nil
      # it_behaves_like 'ToNG', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン][存在しない/ない]ロック日時がない（未ロック）' do
      # it_behaves_like 'NG' # Tips: トークンが存在しない為、ロック日時がない
      # Tips: ActionController::RoutingError: Not Found
      # it_behaves_like 'ToNG', nil, nil
    end
    shared_examples_for '[ログイン中/削除予約済み][存在しない/ない]ロック日時がない（未ロック）' do
      # it_behaves_like 'NG' # Tips: トークンが存在しない為、ロック日時がない
      # Tips: ActionController::RoutingError: Not Found
      # it_behaves_like 'ToNG', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン][存在する]ロック日時がある（ロック中）' do
      it_behaves_like 'OK'
      it_behaves_like 'ToOK', nil, 'devise.unlocks.unlocked'
    end
    shared_examples_for '[ログイン中/削除予約済み][存在する]ロック日時がある（ロック中）' do
      it_behaves_like 'OK'
      it_behaves_like 'ToOK', nil, nil
      # it_behaves_like 'NG'
      # it_behaves_like 'ToNG', 'devise.failure.already_authenticated', nil
    end

    shared_examples_for '[未ログイン]トークンが存在する' do
      include_context 'アカウントロック解除トークン作成'
      it_behaves_like '[未ログイン][存在する]ロック日時がない（未ロック）'
      it_behaves_like '[未ログイン][存在する]ロック日時がある（ロック中）'
    end
    shared_examples_for '[ログイン中/削除予約済み]トークンが存在する' do
      include_context 'アカウントロック解除トークン作成'
      it_behaves_like '[ログイン中/削除予約済み][存在する]ロック日時がない（未ロック）'
      it_behaves_like '[ログイン中/削除予約済み][存在する]ロック日時がある（ロック中）'
    end
    shared_examples_for '[未ログイン]トークンが存在しない' do
      let!(:unlock_token) { NOT_TOKEN }
      it_behaves_like '[未ログイン][存在しない/ない]ロック日時がない（未ロック）'
      # it_behaves_like '[未ログイン][存在しない]ロック日時がある（ロック中）' # Tips: トークンが存在しない為、ロック日時がない
    end
    shared_examples_for '[ログイン中/削除予約済み]トークンが存在しない' do
      let!(:unlock_token) { NOT_TOKEN }
      it_behaves_like '[ログイン中/削除予約済み][存在しない/ない]ロック日時がない（未ロック）'
      # it_behaves_like '[ログイン中/削除予約済み][存在しない]ロック日時がある（ロック中）' # Tips: トークンが存在しない為、ロック日時がない
    end
    shared_examples_for '[未ログイン]トークンがない' do
      let!(:unlock_token) { NO_TOKEN }
      it_behaves_like '[未ログイン][存在しない/ない]ロック日時がない（未ロック）'
      # it_behaves_like '[未ログイン][ない]ロック日時がある（ロック中）' # Tips: トークンが存在しない為、ロック日時がない
    end
    shared_examples_for '[ログイン中/削除予約済み]トークンがない' do
      let!(:unlock_token) { NO_TOKEN }
      it_behaves_like '[ログイン中/削除予約済み][存在しない/ない]ロック日時がない（未ロック）'
      # it_behaves_like '[ログイン中/削除予約済み][ない]ロック日時がある（ロック中）' # Tips: トークンが存在しない為、ロック日時がない
    end

    context '未ログイン' do
      it_behaves_like '[未ログイン]トークンが存在する'
      it_behaves_like '[未ログイン]トークンが存在しない'
      it_behaves_like '[未ログイン]トークンがない'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[ログイン中/削除予約済み]トークンが存在する'
      it_behaves_like '[ログイン中/削除予約済み]トークンが存在しない'
      it_behaves_like '[ログイン中/削除予約済み]トークンがない'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it_behaves_like '[ログイン中/削除予約済み]トークンが存在する'
      it_behaves_like '[ログイン中/削除予約済み]トークンが存在しない'
      it_behaves_like '[ログイン中/削除予約済み]トークンがない'
    end
  end
end
