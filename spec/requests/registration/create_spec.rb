require 'rails_helper'

RSpec.describe 'Registration', type: :request do
  # POST /registration/member（ベースドメイン） メンバー登録(処理)
  # POST /registration/member.json（ベースドメイン） メンバー登録API
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  #   招待完了日時: ない（未登録）, ある（登録済み） → データ作成
  #   トークン: 存在する, 存在しない, ない → データ作成
  #   有効なパラメータ, 無効なパラメータ → 事前にデータ作成
  #   ベースドメイン, 存在するサブドメイン, 存在しないサブドメイン → 事前にデータ作成
  describe 'POST /create' do
    include_context 'リクエストスペース作成'
    let!(:valid_attributes) { FactoryBot.attributes_for(:user) }
    let!(:invalid_attributes) { FactoryBot.attributes_for(:user, name: nil) }

    # テスト内容
    shared_examples_for 'OK' do
      let!(:start_time) { Time.current - 1.second }
      it '招待完了日時が変更される' do
        post create_member_registration_path(invitation_token: invitation_token), params: { user: attributes }, headers: headers
        expect(User.find(@send_user.id).invitation_completed_at).to be_between(start_time, Time.current)
      end
      it '(json)招待完了日時が変更される' do
        post create_member_registration_path(invitation_token: invitation_token, format: :json), params: { user: attributes }, headers: headers
        expect(User.find(@send_user.id).invitation_completed_at).to be_between(start_time, Time.current)
      end
    end
    shared_examples_for 'NG' do
      it '招待完了日時が変更されない' do
        post create_member_registration_path(invitation_token: invitation_token), params: { user: attributes }, headers: headers
        expect(User.find(@send_user.id).invitation_completed_at).to eq(@send_user.invitation_completed_at)
      end
      it '(json)招待完了日時が変更されない' do
        post create_member_registration_path(invitation_token: invitation_token, format: :json), params: { user: attributes }, headers: headers
        expect(User.find(@send_user.id).invitation_completed_at).to eq(@send_user.invitation_completed_at)
      end
    end

    shared_examples_for 'ToOK' do |alert, notice|
      it 'トップページにリダイレクト' do
        post create_member_registration_path(invitation_token: invitation_token), params: { user: attributes }, headers: headers
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
      it '(json)成功ステータス' do
        post create_member_registration_path(invitation_token: invitation_token, format: :json), params: { user: attributes }, headers: headers
        expect(response).to be_ok
        expect(JSON.parse(response.body)['status']).to eq('OK')
        expect(JSON.parse(response.body)['notice']).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end
    shared_examples_for 'ToError' do
      it '成功ステータス' do # Tips: 再入力
        post create_member_registration_path(invitation_token: invitation_token), params: { user: attributes }, headers: headers
        expect(response).to be_successful
      end
      it '(json)失敗レスポンス' do
        post create_member_registration_path(invitation_token: invitation_token, format: :json), params: { user: attributes }, headers: headers
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['status']).to eq('NG')
        expect(JSON.parse(response.body)['error'].count).not_to eq(0)
      end
    end
    shared_examples_for 'ToNot' do |error|
      it '存在しないステータス' do
        post create_member_registration_path(invitation_token: invitation_token), params: { user: attributes }, headers: headers
        expect(response).to be_not_found
      end
      it '(json)存在しないエラー' do
        post create_member_registration_path(invitation_token: invitation_token, format: :json), params: { user: attributes }, headers: headers
        expect(response).to be_not_found
        message = response.body.present? ? JSON.parse(response.body)['error'] : nil
        expect(message).to error.present? ? eq(I18n.t(error)) : be_nil
      end
    end
    shared_examples_for 'ToTop' do |alert, notice, error|
      it 'トップページにリダイレクト' do
        post create_member_registration_path(invitation_token: invitation_token), params: { user: attributes }, headers: headers
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
      it '(json)権限エラー' do
        post create_member_registration_path(invitation_token: invitation_token, format: :json), params: { user: attributes }, headers: headers
        expect(response).to be_forbidden
        message = response.body.present? ? JSON.parse(response.body)['error'] : nil
        expect(message).to error.present? ? eq(I18n.t(error)) : be_nil
      end
    end
    shared_examples_for 'ToLogin' do |alert, notice, error|
      it 'ログインにリダイレクト' do
        post create_member_registration_path(invitation_token: invitation_token), params: { user: attributes }, headers: headers
        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
      it '(json)権限エラー' do
        post create_member_registration_path(invitation_token: invitation_token, format: :json), params: { user: attributes }, headers: headers
        expect(response).to be_forbidden
        message = response.body.present? ? JSON.parse(response.body)['error'] : nil
        expect(message).to error.present? ? eq(I18n.t(error)) : be_nil
      end
    end

    # テストケース
    shared_examples_for '[未ログイン][未登録][存在する][有効]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'OK'
      it_behaves_like 'ToOK', nil, 'notice.registration.create'
    end
    shared_examples_for '[ログイン中/削除予約済み][未登録][存在する][*]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'NG'
      it_behaves_like 'ToTop', 'alert.user.invitation_token.already_sign_in', nil, 'alert.user.invitation_token.already_sign_in'
    end
    shared_examples_for '[未ログイン][登録済み][存在する][*]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'NG'
      it_behaves_like 'ToLogin', 'alert.user.invitation_token.invalid', nil, 'alert.user.invitation_token.invalid'
    end
    shared_examples_for '[ログイン中/削除予約済み][登録済み][存在する][*]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'NG'
      it_behaves_like 'ToTop', 'alert.user.invitation_token.invalid', nil, 'alert.user.invitation_token.invalid'
    end
    shared_examples_for '[未ログイン][未登録][存在しない][*]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      # it_behaves_like 'NG' # Tips: トークンが存在しない為、対象レコードがない
      it_behaves_like 'ToLogin', 'alert.user.invitation_token.invalid', nil, 'alert.user.invitation_token.invalid'
    end
    shared_examples_for '[ログイン中/削除予約済み][未登録][存在しない][*]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      # it_behaves_like 'NG' # Tips: トークンが存在しない為、対象レコードがない
      it_behaves_like 'ToTop', 'alert.user.invitation_token.invalid', nil, 'alert.user.invitation_token.invalid'
    end
    shared_examples_for '[未ログイン][未登録][ない][*]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      # it_behaves_like 'NG' # Tips: トークンが存在しない為、対象レコードがない
      it_behaves_like 'ToLogin', 'alert.user.invitation_token.blank', nil, 'alert.user.invitation_token.blank'
    end
    shared_examples_for '[ログイン中/削除予約済み][未登録][ない][*]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      # it_behaves_like 'NG' # Tips: トークンが存在しない為、対象レコードがない
      it_behaves_like 'ToTop', 'alert.user.invitation_token.blank', nil, 'alert.user.invitation_token.blank'
    end
    shared_examples_for '[未ログイン][未登録][存在する][無効]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'NG'
      it_behaves_like 'ToError'
    end
    shared_examples_for '[*][*][存在する][*]存在するサブドメイン' do
      let!(:headers) { @space_header }
      it_behaves_like 'NG'
      it_behaves_like 'ToNot', 'errors.messages.domain_error'
    end
    shared_examples_for '[*][*][存在しない/ない][*]存在するサブドメイン' do
      let!(:headers) { @space_header }
      # it_behaves_like 'NG' # Tips: トークンが存在しない為、対象レコードがない
      it_behaves_like 'ToNot', 'errors.messages.domain_error'
    end
    shared_examples_for '[*][*][存在する][*]存在しないサブドメイン' do
      let!(:headers) { NOT_SPACE_HEADER }
      it_behaves_like 'NG'
      it_behaves_like 'ToNot', 'errors.messages.domain_error'
    end
    shared_examples_for '[*][*][存在しない/ない][*]存在しないサブドメイン' do
      let!(:headers) { NOT_SPACE_HEADER }
      # it_behaves_like 'NG' # Tips: トークンが存在しない為、対象レコードがない
      it_behaves_like 'ToNot', 'errors.messages.domain_error'
    end

    shared_examples_for '[未ログイン][未登録][存在する]有効なパラメータ' do
      let!(:attributes) { valid_attributes }
      it_behaves_like '[未ログイン][未登録][存在する][有効]ベースドメイン'
      it_behaves_like '[*][*][存在する][*]存在するサブドメイン'
      it_behaves_like '[*][*][存在する][*]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み][未登録][存在する]有効なパラメータ' do
      let!(:attributes) { valid_attributes }
      it_behaves_like '[ログイン中/削除予約済み][未登録][存在する][*]ベースドメイン'
      it_behaves_like '[*][*][存在する][*]存在するサブドメイン'
      it_behaves_like '[*][*][存在する][*]存在しないサブドメイン'
    end
    shared_examples_for '[未ログイン][登録済み][存在する]有効なパラメータ' do
      let!(:attributes) { valid_attributes }
      it_behaves_like '[未ログイン][登録済み][存在する][*]ベースドメイン'
      it_behaves_like '[*][*][存在する][*]存在するサブドメイン'
      it_behaves_like '[*][*][存在する][*]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み][登録済み][存在する]有効なパラメータ' do
      let!(:attributes) { valid_attributes }
      it_behaves_like '[ログイン中/削除予約済み][登録済み][存在する][*]ベースドメイン'
      it_behaves_like '[*][*][存在する][*]存在するサブドメイン'
      it_behaves_like '[*][*][存在する][*]存在しないサブドメイン'
    end
    shared_examples_for '[未ログイン][未登録][存在しない]有効なパラメータ' do
      let!(:attributes) { valid_attributes }
      it_behaves_like '[未ログイン][未登録][存在しない][*]ベースドメイン'
      it_behaves_like '[*][*][存在しない/ない][*]存在するサブドメイン'
      it_behaves_like '[*][*][存在しない/ない][*]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み][未登録][存在しない]有効なパラメータ' do
      let!(:attributes) { valid_attributes }
      it_behaves_like '[ログイン中/削除予約済み][未登録][存在しない][*]ベースドメイン'
      it_behaves_like '[*][*][存在しない/ない][*]存在するサブドメイン'
      it_behaves_like '[*][*][存在しない/ない][*]存在しないサブドメイン'
    end
    shared_examples_for '[未ログイン][未登録][ない]有効なパラメータ' do
      let!(:attributes) { valid_attributes }
      it_behaves_like '[未ログイン][未登録][ない][*]ベースドメイン'
      it_behaves_like '[*][*][存在しない/ない][*]存在するサブドメイン'
      it_behaves_like '[*][*][存在しない/ない][*]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み][未登録][ない]有効なパラメータ' do
      let!(:attributes) { valid_attributes }
      it_behaves_like '[ログイン中/削除予約済み][未登録][ない][*]ベースドメイン'
      it_behaves_like '[*][*][存在しない/ない][*]存在するサブドメイン'
      it_behaves_like '[*][*][存在しない/ない][*]存在しないサブドメイン'
    end
    shared_examples_for '[未ログイン][未登録][存在する]無効なパラメータ' do
      let!(:attributes) { invalid_attributes }
      it_behaves_like '[未ログイン][未登録][存在する][無効]ベースドメイン'
      it_behaves_like '[*][*][存在する][*]存在するサブドメイン'
      it_behaves_like '[*][*][存在する][*]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み][未登録][存在する]無効なパラメータ' do
      let!(:attributes) { invalid_attributes }
      it_behaves_like '[ログイン中/削除予約済み][未登録][存在する][*]ベースドメイン'
      it_behaves_like '[*][*][存在する][*]存在するサブドメイン'
      it_behaves_like '[*][*][存在する][*]存在しないサブドメイン'
    end
    shared_examples_for '[未ログイン][登録済み][存在する]無効なパラメータ' do
      let!(:attributes) { invalid_attributes }
      it_behaves_like '[未ログイン][登録済み][存在する][*]ベースドメイン'
      it_behaves_like '[*][*][存在する][*]存在するサブドメイン'
      it_behaves_like '[*][*][存在する][*]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み][登録済み][存在する]無効なパラメータ' do
      let!(:attributes) { invalid_attributes }
      it_behaves_like '[ログイン中/削除予約済み][登録済み][存在する][*]ベースドメイン'
      it_behaves_like '[*][*][存在する][*]存在するサブドメイン'
      it_behaves_like '[*][*][存在する][*]存在しないサブドメイン'
    end
    shared_examples_for '[未ログイン][未登録][存在しない]無効なパラメータ' do
      let!(:attributes) { invalid_attributes }
      it_behaves_like '[未ログイン][未登録][存在しない][*]ベースドメイン'
      it_behaves_like '[*][*][存在しない/ない][*]存在するサブドメイン'
      it_behaves_like '[*][*][存在しない/ない][*]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み][未登録][存在しない]無効なパラメータ' do
      let!(:attributes) { invalid_attributes }
      it_behaves_like '[ログイン中/削除予約済み][未登録][存在しない][*]ベースドメイン'
      it_behaves_like '[*][*][存在しない/ない][*]存在するサブドメイン'
      it_behaves_like '[*][*][存在しない/ない][*]存在しないサブドメイン'
    end
    shared_examples_for '[未ログイン][未登録][ない]無効なパラメータ' do
      let!(:attributes) { invalid_attributes }
      it_behaves_like '[未ログイン][未登録][ない][*]ベースドメイン'
      it_behaves_like '[*][*][存在しない/ない][*]存在するサブドメイン'
      it_behaves_like '[*][*][存在しない/ない][*]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み][未登録][ない]無効なパラメータ' do
      let!(:attributes) { invalid_attributes }
      it_behaves_like '[ログイン中/削除予約済み][未登録][ない][*]ベースドメイン'
      it_behaves_like '[*][*][存在しない/ない][*]存在するサブドメイン'
      it_behaves_like '[*][*][存在しない/ない][*]存在しないサブドメイン'
    end

    shared_examples_for '[未ログイン][未登録]トークンが存在する' do
      include_context '招待トークン作成'
      it_behaves_like '[未ログイン][未登録][存在する]有効なパラメータ'
      it_behaves_like '[未ログイン][未登録][存在する]無効なパラメータ'
    end
    shared_examples_for '[ログイン中/削除予約済み][未登録]トークンが存在する' do
      include_context '招待トークン作成'
      it_behaves_like '[ログイン中/削除予約済み][未登録][存在する]有効なパラメータ'
      it_behaves_like '[ログイン中/削除予約済み][未登録][存在する]無効なパラメータ'
    end
    shared_examples_for '[未ログイン][登録済み]トークンが存在する' do
      include_context '招待トークン作成'
      it_behaves_like '[未ログイン][登録済み][存在する]有効なパラメータ'
      it_behaves_like '[未ログイン][登録済み][存在する]無効なパラメータ'
    end
    shared_examples_for '[ログイン中/削除予約済み][登録済み]トークンが存在する' do
      include_context '招待トークン作成'
      it_behaves_like '[ログイン中/削除予約済み][登録済み][存在する]有効なパラメータ'
      it_behaves_like '[ログイン中/削除予約済み][登録済み][存在する]無効なパラメータ'
    end
    shared_examples_for '[未ログイン][未登録]トークンが存在しない' do
      let!(:invitation_token) { NOT_TOKEN }
      it_behaves_like '[未ログイン][未登録][存在しない]有効なパラメータ'
      it_behaves_like '[未ログイン][未登録][存在しない]無効なパラメータ'
    end
    shared_examples_for '[ログイン中/削除予約済み][未登録]トークンが存在しない' do
      let!(:invitation_token) { NOT_TOKEN }
      it_behaves_like '[ログイン中/削除予約済み][未登録][存在しない]有効なパラメータ'
      it_behaves_like '[ログイン中/削除予約済み][未登録][存在しない]無効なパラメータ'
    end
    shared_examples_for '[未ログイン][未登録]トークンがない' do
      let!(:invitation_token) { NO_TOKEN }
      it_behaves_like '[未ログイン][未登録][ない]有効なパラメータ'
      it_behaves_like '[未ログイン][未登録][ない]無効なパラメータ'
    end
    shared_examples_for '[ログイン中/削除予約済み][未登録]トークンがない' do
      let!(:invitation_token) { NO_TOKEN }
      it_behaves_like '[ログイン中/削除予約済み][未登録][ない]有効なパラメータ'
      it_behaves_like '[ログイン中/削除予約済み][未登録][ない]無効なパラメータ'
    end

    shared_examples_for '[未ログイン]招待完了日時がない（未登録）' do
      let!(:completed) { false }
      it_behaves_like '[未ログイン][未登録]トークンが存在する'
      it_behaves_like '[未ログイン][未登録]トークンが存在しない'
      it_behaves_like '[未ログイン][未登録]トークンがない'
    end
    shared_examples_for '[ログイン中/削除予約済み]招待完了日時がない（未登録）' do
      let!(:completed) { false }
      it_behaves_like '[ログイン中/削除予約済み][未登録]トークンが存在する'
      it_behaves_like '[ログイン中/削除予約済み][未登録]トークンが存在しない'
      it_behaves_like '[ログイン中/削除予約済み][未登録]トークンがない'
    end
    shared_examples_for '[未ログイン]招待完了日時がある（登録済み）' do
      let!(:completed) { true }
      it_behaves_like '[未ログイン][登録済み]トークンが存在する'
      # it_behaves_like '[未ログイン][登録済み]トークンが存在しない' # Tips: トークンが存在しない為、招待完了日時がない（未登録）
      # it_behaves_like '[未ログイン][登録済み]トークンがない' # Tips: トークンがない為、招待完了日時がない（未登録）
    end
    shared_examples_for '[ログイン中/削除予約済み]招待完了日時がある（登録済み）' do
      let!(:completed) { true }
      it_behaves_like '[ログイン中/削除予約済み][登録済み]トークンが存在する'
      # it_behaves_like '[ログイン中/削除予約済み][登録済み]トークンが存在しない' # Tips: トークンが存在しない為、招待完了日時がない（未登録）
      # it_behaves_like '[ログイン中/削除予約済み][登録済み]トークンがない' # Tips: トークンがない為、招待完了日時がない（未登録）
    end

    context '未ログイン' do
      it_behaves_like '[未ログイン]招待完了日時がない（未登録）'
      it_behaves_like '[未ログイン]招待完了日時がある（登録済み）'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[ログイン中/削除予約済み]招待完了日時がない（未登録）'
      it_behaves_like '[ログイン中/削除予約済み]招待完了日時がある（登録済み）'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it_behaves_like '[ログイン中/削除予約済み]招待完了日時がない（未登録）'
      it_behaves_like '[ログイン中/削除予約済み]招待完了日時がある（登録済み）'
    end
  end
end
