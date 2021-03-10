require 'rails_helper'

RSpec.describe 'Users::Confirmations', type: :request do
  include_context 'リクエストスペース作成'

  # GET /users/confirmation/new メールアドレス確認[メール再送]
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  #   ベースドメイン, 存在するサブドメイン, 存在しないサブドメイン → 事前にデータ作成
  describe 'GET /new' do
    # テスト内容
    shared_examples_for 'ToOK' do
      it '成功ステータス' do
        get new_user_confirmation_path, headers: headers
        expect(response).to be_successful
      end
    end
    shared_examples_for 'ToBase' do |alert, notice|
      it 'ベースドメインにリダイレクト' do
        get new_user_confirmation_path, headers: headers
        expect(response).to redirect_to("//#{Settings['base_domain']}#{new_user_confirmation_path}")
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end

    # テストケース
    shared_examples_for '[未ログイン]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'ToOK'
    end
    shared_examples_for '[ログイン中/削除予約済み]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'ToOK' # Tips: リンクないけど、送れても良さそう
    end
    shared_examples_for '[*]存在するサブドメイン' do
      let!(:headers) { @space_header }
      it_behaves_like 'ToBase', nil, nil
    end
    shared_examples_for '[*]存在しないサブドメイン' do
      let!(:headers) { NOT_SPACE_HEADER }
      it_behaves_like 'ToBase', nil, nil
    end

    context '未ログイン' do
      it_behaves_like '[未ログイン]ベースドメイン'
      it_behaves_like '[*]存在するサブドメイン'
      it_behaves_like '[*]存在しないサブドメイン'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[ログイン中/削除予約済み]ベースドメイン'
      it_behaves_like '[*]存在するサブドメイン'
      it_behaves_like '[*]存在しないサブドメイン'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it_behaves_like '[ログイン中/削除予約済み]ベースドメイン'
      it_behaves_like '[*]存在するサブドメイン'
      it_behaves_like '[*]存在しないサブドメイン'
    end
  end

  # POST /users/confirmation メールアドレス確認[メール再送](処理)
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  #   招待依頼日時: ない, ある → データ作成
  #   招待完了日時: ない, ある → データ作成
  #   有効なパラメータ, 無効なパラメータ → 事前にデータ作成
  #   ベースドメイン, 存在するサブドメイン, 存在しないサブドメイン → 事前にデータ作成
  describe 'POST /create' do
    let!(:send_user) { FactoryBot.create(:user, confirmed_at: nil) }
    let!(:valid_attributes) { FactoryBot.attributes_for(:user, email: send_user.email) }
    let!(:invalid_attributes) { FactoryBot.attributes_for(:user, email: nil) }

    shared_context '招待依頼・完了日時変更' do |completed_at|
      before do
        if requested_at.present? || completed_at.present?
          send_user.invitation_requested_at = requested_at
          send_user.invitation_completed_at = completed_at
          send_user.save!
        end
      end
    end

    # テスト内容
    shared_examples_for 'ToOK' do
      it '成功ステータス' do
        post user_confirmation_path, params: { user: attributes }, headers: headers
        expect(response).to be_successful
      end
    end
    shared_examples_for 'ToNot' do
      it '存在しないステータス' do
        post user_confirmation_path, params: { user: attributes }, headers: headers
        expect(response).to be_not_found
      end
    end
    shared_examples_for 'ToLogin' do |alert, notice|
      it 'ログインにリダイレクト' do
        post user_confirmation_path, params: { user: attributes }, headers: headers
        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end

    # テストケース
    shared_examples_for '[*][ない][*][有効]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'ToLogin', nil, 'devise.confirmations.send_instructions'
    end
    shared_examples_for '[*][ある][ない][有効]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'ToLogin', nil, 'notice.user.invitation_token.send_instructions'
    end
    shared_examples_for '[*][ある][ある][有効]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'ToLogin', nil, 'devise.confirmations.send_instructions'
    end
    shared_examples_for '[*][*][*][無効]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'ToOK' # Tips: 再入力
    end
    shared_examples_for '[*][*][*][*]存在するサブドメイン' do
      let!(:headers) { @space_header }
      it_behaves_like 'ToNot'
    end
    shared_examples_for '[*][*][*][*]存在しないサブドメイン' do
      let!(:headers) { NOT_SPACE_HEADER }
      it_behaves_like 'ToNot'
    end

    shared_examples_for '[*][ない][*]有効なパラメータ' do # Tips: ログイン中も出来ても良さそう
      let!(:attributes) { valid_attributes }
      it_behaves_like '[*][ない][*][有効]ベースドメイン'
      it_behaves_like '[*][*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[*][ある][ない]有効なパラメータ' do
      let!(:attributes) { valid_attributes }
      it_behaves_like '[*][ある][ない][有効]ベースドメイン'
      it_behaves_like '[*][*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[*][ある][ある]有効なパラメータ' do
      let!(:attributes) { valid_attributes }
      it_behaves_like '[*][ある][ある][有効]ベースドメイン'
      it_behaves_like '[*][*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[*][*][*]無効なパラメータ' do
      let!(:attributes) { invalid_attributes }
      it_behaves_like '[*][*][*][無効]ベースドメイン'
      it_behaves_like '[*][*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*][*]存在しないサブドメイン'
    end

    shared_examples_for '[*][ない]招待完了日時がない' do
      include_context '招待依頼・完了日時変更', nil
      it_behaves_like '[*][ない][*]有効なパラメータ'
      it_behaves_like '[*][*][*]無効なパラメータ'
    end
    shared_examples_for '[*][ある]招待完了日時がない' do
      include_context '招待依頼・完了日時変更', nil
      it_behaves_like '[*][ある][ない]有効なパラメータ'
      it_behaves_like '[*][*][*]無効なパラメータ'
    end
    shared_examples_for '[*][ない]招待完了日時がある' do
      include_context '招待依頼・完了日時変更', Time.current
      it_behaves_like '[*][ない][*]有効なパラメータ'
      it_behaves_like '[*][*][*]無効なパラメータ'
    end
    shared_examples_for '[*][ある]招待完了日時がある' do
      include_context '招待依頼・完了日時変更', Time.current
      it_behaves_like '[*][ある][ある]有効なパラメータ'
      it_behaves_like '[*][*][*]無効なパラメータ'
    end

    shared_examples_for '[*]招待依頼日時がない' do
      let!(:requested_at) { nil }
      it_behaves_like '[*][ない]招待完了日時がない'
      it_behaves_like '[*][ない]招待完了日時がある'
    end
    shared_examples_for '[*]招待依頼日時がある' do
      let!(:requested_at) { Time.current - 1.second }
      it_behaves_like '[*][ある]招待完了日時がない'
      it_behaves_like '[*][ある]招待完了日時がある'
    end

    context '未ログイン' do
      it_behaves_like '[*]招待依頼日時がない'
      it_behaves_like '[*]招待依頼日時がある'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[*]招待依頼日時がない'
      it_behaves_like '[*]招待依頼日時がある'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it_behaves_like '[*]招待依頼日時がない'
      it_behaves_like '[*]招待依頼日時がある'
    end
  end

  # GET /users/confirmation メールアドレス確認(処理)
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  #   トークン: 期限内, 期限切れ, 存在しない, ない → データ作成
  #   確認日時: ない（未確認）, 確認送信日時より前（未確認）, 確認送信日時より後（確認済み） → データ作成
  #   ベースドメイン, 存在するサブドメイン, 存在しないサブドメイン → 事前にデータ作成
  describe 'GET /show' do
    # テスト内容
    shared_examples_for 'OK' do
      let!(:start_time) { Time.now.utc - 1.second }
      it '確認日時が現在日時に変更される' do
        get user_confirmation_path(confirmation_token: confirmation_token), headers: headers
        expect(User.find(@send_user.id).confirmed_at).to be_between(start_time, Time.now.utc)
      end
    end
    shared_examples_for 'NG' do
      it '確認日時が変更されない' do
        get user_confirmation_path(confirmation_token: confirmation_token), headers: headers
        expect(User.find(@send_user.id).confirmed_at).to eq(@send_user.confirmed_at)
      end
    end

    shared_examples_for 'ToTop' do |alert, notice|
      it 'トップページにリダイレクト' do
        get user_confirmation_path(confirmation_token: confirmation_token), headers: headers
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end
    shared_examples_for 'ToLogin' do |alert, notice|
      it 'ログインにリダイレクト' do
        get user_confirmation_path(confirmation_token: confirmation_token), headers: headers
        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end
    shared_examples_for 'ToNew' do |alert, notice|
      it 'メールアドレス確認[メール再送]にリダイレクト' do
        get user_confirmation_path(confirmation_token: confirmation_token), headers: headers
        expect(response).to redirect_to(new_user_confirmation_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end
    shared_examples_for 'ToBase' do |alert, notice|
      it 'ベースドメインにリダイレクト' do
        get user_confirmation_path(confirmation_token: confirmation_token), headers: headers
        expect(response).to redirect_to("//#{Settings['base_domain']}#{user_confirmation_path(confirmation_token: confirmation_token)}")
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end

    # テストケース
    shared_examples_for '[未ログイン][期限内][未確認]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'OK'
      it_behaves_like 'ToLogin', nil, 'devise.confirmations.confirmed'
    end
    shared_examples_for '[ログイン中/削除予約済み][期限内][未確認]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'OK'
      it_behaves_like 'ToTop', nil, 'devise.confirmations.confirmed'
    end
    shared_examples_for '[*][期限切れ][未確認]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'NG'
      it_behaves_like 'ToNew', 'activerecord.errors.models.user.attributes.confirmation_token.invalid', nil
    end
    shared_examples_for '[*][存在しない/ない][未確認]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      # it_behaves_like 'NG' # Tips: tokenが存在しない為、確認日時がない
      it_behaves_like 'ToNew', 'activerecord.errors.models.user.attributes.confirmation_token.invalid', nil
    end
    shared_examples_for '[未ログイン][期限内][確認済み]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'NG'
      it_behaves_like 'ToLogin', 'errors.messages.already_confirmed', nil
    end
    shared_examples_for '[ログイン中/削除予約済み][期限内][確認済み]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'NG'
      it_behaves_like 'ToLogin', 'errors.messages.already_confirmed', nil # Tips: ログインからトップにリダイレクト
    end
    shared_examples_for '[*][期限切れ][確認済み]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'NG'
      it_behaves_like 'ToNew', 'activerecord.errors.models.user.attributes.confirmation_token.invalid', nil
    end
    shared_examples_for '[*][期限内/期限切れ][*]存在するサブドメイン' do
      let!(:headers) { @space_header }
      it_behaves_like 'NG'
      it_behaves_like 'ToBase', nil, nil
    end
    shared_examples_for '[*][存在しない/ない][*]存在するサブドメイン' do
      let!(:headers) { @space_header }
      # it_behaves_like 'NG' # Tips: tokenが存在しない為、確認日時がない
      it_behaves_like 'ToBase', nil, nil
    end
    shared_examples_for '[*][期限内/期限切れ][*]存在しないサブドメイン' do
      let!(:headers) { NOT_SPACE_HEADER }
      it_behaves_like 'NG'
      it_behaves_like 'ToBase', nil, nil
    end
    shared_examples_for '[*][存在しない/ない][*]存在しないサブドメイン' do
      let!(:headers) { NOT_SPACE_HEADER }
      # it_behaves_like 'NG' # Tips: tokenが存在しない為、確認日時がない
      it_behaves_like 'ToBase', nil, nil
    end

    shared_examples_for '[未ログイン][期限内]確認日時がない（未確認）' do
      it_behaves_like '[未ログイン][期限内][未確認]ベースドメイン'
      it_behaves_like '[*][期限内/期限切れ][*]存在するサブドメイン'
      it_behaves_like '[*][期限内/期限切れ][*]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み][期限内]確認日時がない（未確認）' do # Tips: ログイン中も出来ても良さそう
      it_behaves_like '[ログイン中/削除予約済み][期限内][未確認]ベースドメイン'
      it_behaves_like '[*][期限内/期限切れ][*]存在するサブドメイン'
      it_behaves_like '[*][期限内/期限切れ][*]存在しないサブドメイン'
    end
    shared_examples_for '[*][期限切れ]確認日時がない（未確認）' do
      it_behaves_like '[*][期限切れ][未確認]ベースドメイン'
      it_behaves_like '[*][期限内/期限切れ][*]存在するサブドメイン'
      it_behaves_like '[*][期限内/期限切れ][*]存在しないサブドメイン'
    end
    shared_examples_for '[*][存在しない/ない]確認日時がない（未確認）' do
      it_behaves_like '[*][存在しない/ない][未確認]ベースドメイン'
      it_behaves_like '[*][存在しない/ない][*]存在するサブドメイン'
      it_behaves_like '[*][存在しない/ない][*]存在しないサブドメイン'
    end
    shared_examples_for '[未ログイン][期限内]確認日時が確認送信日時より前（未確認）' do
      include_context 'メールアドレス確認トークン確認', true
      it_behaves_like '[未ログイン][期限内][未確認]ベースドメイン'
      it_behaves_like '[*][期限内/期限切れ][*]存在するサブドメイン'
      it_behaves_like '[*][期限内/期限切れ][*]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み][期限内]確認日時が確認送信日時より前（未確認）' do # Tips: ログイン中も出来ても良さそう
      include_context 'メールアドレス確認トークン確認', true
      it_behaves_like '[ログイン中/削除予約済み][期限内][未確認]ベースドメイン'
      it_behaves_like '[*][期限内/期限切れ][*]存在するサブドメイン'
      it_behaves_like '[*][期限内/期限切れ][*]存在しないサブドメイン'
    end
    shared_examples_for '[*][期限切れ]確認日時が確認送信日時より前（未確認）' do
      include_context 'メールアドレス確認トークン確認', true
      it_behaves_like '[*][期限切れ][未確認]ベースドメイン'
      it_behaves_like '[*][期限内/期限切れ][*]存在するサブドメイン'
      it_behaves_like '[*][期限内/期限切れ][*]存在しないサブドメイン'
    end
    shared_examples_for '[未ログイン][期限内]確認日時が確認送信日時より後（確認済み）' do
      include_context 'メールアドレス確認トークン確認', false
      it_behaves_like '[未ログイン][期限内][確認済み]ベースドメイン'
      it_behaves_like '[*][期限内/期限切れ][*]存在するサブドメイン'
      it_behaves_like '[*][期限内/期限切れ][*]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み][期限内]確認日時が確認送信日時より後（確認済み）' do
      include_context 'メールアドレス確認トークン確認', false
      it_behaves_like '[ログイン中/削除予約済み][期限内][確認済み]ベースドメイン'
      it_behaves_like '[*][期限内/期限切れ][*]存在するサブドメイン'
      it_behaves_like '[*][期限内/期限切れ][*]存在しないサブドメイン'
    end
    shared_examples_for '[*][期限切れ]確認日時が確認送信日時より後（確認済み）' do
      include_context 'メールアドレス確認トークン確認', false
      it_behaves_like '[*][期限切れ][確認済み]ベースドメイン'
      it_behaves_like '[*][期限内/期限切れ][*]存在するサブドメイン'
      it_behaves_like '[*][期限内/期限切れ][*]存在しないサブドメイン'
    end

    shared_examples_for '[未ログイン]トークンが期限内' do
      include_context 'メールアドレス確認トークン作成', true
      it_behaves_like '[未ログイン][期限内]確認日時がない（未確認）'
      it_behaves_like '[未ログイン][期限内]確認日時が確認送信日時より前（未確認）'
      it_behaves_like '[未ログイン][期限内]確認日時が確認送信日時より後（確認済み）'
    end
    shared_examples_for '[ログイン中/削除予約済み]トークンが期限内' do
      include_context 'メールアドレス確認トークン作成', true
      it_behaves_like '[ログイン中/削除予約済み][期限内]確認日時がない（未確認）'
      it_behaves_like '[ログイン中/削除予約済み][期限内]確認日時が確認送信日時より前（未確認）'
      it_behaves_like '[ログイン中/削除予約済み][期限内]確認日時が確認送信日時より後（確認済み）'
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
