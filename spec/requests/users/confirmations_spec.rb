require 'rails_helper'

RSpec.describe 'Users::Confirmations', type: :request do
  # GET /users/confirmation/new メールアドレス確認[メール再送]
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  describe 'GET #new' do
    # テスト内容
    shared_examples_for 'ToOK' do
      it '成功ステータス' do
        get new_user_confirmation_path
        expect(response).to be_successful
      end
    end

    # テストケース
    context '未ログイン' do
      it_behaves_like 'ToOK'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like 'ToOK' # Tips: リンクないけど、送れても良さそう
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it_behaves_like 'ToOK' # Tips: リンクないけど、送れても良さそう
    end
  end

  # POST /users/confirmation/new メールアドレス確認[メール再送](処理)
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  #   有効なパラメータ, 無効なパラメータ → 事前にデータ作成
  describe 'POST #create' do
    let!(:send_user) { FactoryBot.create(:user, confirmed_at: nil) }
    let!(:valid_attributes) { FactoryBot.attributes_for(:user, email: send_user.email) }
    let!(:invalid_attributes) { FactoryBot.attributes_for(:user, email: nil) }

    # テスト内容
    shared_examples_for 'ToError' do
      it '成功ステータス' do # Tips: 再入力
        post create_user_confirmation_path, params: { user: attributes }
        expect(response).to be_successful
      end
    end
    shared_examples_for 'ToLogin' do |alert, notice|
      it 'ログインにリダイレクト' do
        post create_user_confirmation_path, params: { user: attributes }
        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end

    # テストケース
    shared_examples_for '[*]有効なパラメータ' do # Tips: ログイン中も出来ても良さそう
      let!(:attributes) { valid_attributes }
      it_behaves_like 'ToLogin', nil, 'devise.confirmations.send_instructions'
    end
    shared_examples_for '[*]無効なパラメータ' do
      let!(:attributes) { invalid_attributes }
      it_behaves_like 'ToError'
    end

    context '未ログイン' do
      it_behaves_like '[*]有効なパラメータ'
      it_behaves_like '[*]無効なパラメータ'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[*]有効なパラメータ'
      it_behaves_like '[*]無効なパラメータ'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it_behaves_like '[*]有効なパラメータ'
      it_behaves_like '[*]無効なパラメータ'
    end
  end

  # GET /users/confirmation メールアドレス確認(処理)
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  #   トークン: 期限内, 期限切れ, 存在しない, ない → データ作成
  #   確認日時: ない（未確認）, 確認送信日時より前（未確認）, 確認送信日時より後（確認済み） → データ作成
  describe 'GET #show' do
    # テスト内容
    shared_examples_for 'OK' do
      let!(:start_time) { Time.now.utc - 1.second }
      it '確認日時が現在日時に変更される' do
        get user_confirmation_path(confirmation_token: confirmation_token)
        expect(User.find(@send_user.id).confirmed_at).to be_between(start_time, Time.now.utc)
      end
    end
    shared_examples_for 'NG' do
      it '確認日時が変更されない' do
        get user_confirmation_path(confirmation_token: confirmation_token)
        expect(User.find(@send_user.id).confirmed_at).to eq(@send_user.confirmed_at)
      end
    end

    shared_examples_for 'ToTop' do |alert, notice|
      it 'トップページにリダイレクト' do
        get user_confirmation_path(confirmation_token: confirmation_token)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end
    shared_examples_for 'ToLogin' do |alert, notice|
      it 'ログインにリダイレクト' do
        get user_confirmation_path(confirmation_token: confirmation_token)
        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end
    shared_examples_for 'ToNew' do |alert, notice|
      it 'メールアドレス確認[メール再送]にリダイレクト' do
        get user_confirmation_path(confirmation_token: confirmation_token)
        expect(response).to redirect_to(new_user_confirmation_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end

    # テストケース
    shared_examples_for '[未ログイン][期限内]確認日時がない（未確認）' do
      it_behaves_like 'OK'
      it_behaves_like 'ToLogin', nil, 'devise.confirmations.confirmed'
    end
    shared_examples_for '[ログイン中][期限内]確認日時がない（未確認）' do # Tips: ログイン中も出来ても良さそう
      it_behaves_like 'OK'
      it_behaves_like 'ToTop', nil, 'devise.confirmations.confirmed'
    end
    shared_examples_for '[*][期限切れ]確認日時がない（未確認）' do
      it_behaves_like 'NG'
      it_behaves_like 'ToNew', 'activerecord.errors.models.user.attributes.confirmation_token.invalid', nil
    end
    shared_examples_for '[*][存在しない/ない]確認日時がない（未確認）' do
      # it_behaves_like 'NG' # Tips: トークンが存在しない為、確認日時がない
      it_behaves_like 'ToNew', 'activerecord.errors.models.user.attributes.confirmation_token.invalid', nil
    end
    shared_examples_for '[未ログイン][期限内]確認日時が確認送信日時より前（未確認）' do
      include_context 'メールアドレス確認トークン確認', true
      it_behaves_like 'OK'
      it_behaves_like 'ToLogin', nil, 'devise.confirmations.confirmed'
    end
    shared_examples_for '[ログイン中][期限内]確認日時が確認送信日時より前（未確認）' do # Tips: ログイン中も出来ても良さそう
      include_context 'メールアドレス確認トークン確認', true
      it_behaves_like 'OK'
      it_behaves_like 'ToTop', nil, 'devise.confirmations.confirmed'
    end
    shared_examples_for '[*][期限切れ]確認日時が確認送信日時より前（未確認）' do
      include_context 'メールアドレス確認トークン確認', true
      it_behaves_like 'NG'
      it_behaves_like 'ToNew', 'activerecord.errors.models.user.attributes.confirmation_token.invalid', nil
    end
    shared_examples_for '[未ログイン][期限内]確認日時が確認送信日時より後（確認済み）' do
      include_context 'メールアドレス確認トークン確認', false
      it_behaves_like 'NG'
      it_behaves_like 'ToLogin', 'errors.messages.already_confirmed', nil
    end
    shared_examples_for '[ログイン中][期限内]確認日時が確認送信日時より後（確認済み）' do
      include_context 'メールアドレス確認トークン確認', false
      it_behaves_like 'NG'
      it_behaves_like 'ToLogin', 'errors.messages.already_confirmed', nil # Tips: ログインからトップにリダイレクト
    end
    shared_examples_for '[*][期限切れ]確認日時が確認送信日時より後（確認済み）' do
      include_context 'メールアドレス確認トークン確認', false
      it_behaves_like 'NG'
      it_behaves_like 'ToNew', 'activerecord.errors.models.user.attributes.confirmation_token.invalid', nil
    end

    shared_examples_for '[未ログイン]トークンが期限内' do
      include_context 'メールアドレス確認トークン作成', true
      it_behaves_like '[未ログイン][期限内]確認日時がない（未確認）'
      it_behaves_like '[未ログイン][期限内]確認日時が確認送信日時より前（未確認）'
      it_behaves_like '[未ログイン][期限内]確認日時が確認送信日時より後（確認済み）'
    end
    shared_examples_for '[ログイン中/削除予約済み]トークンが期限内' do
      include_context 'メールアドレス確認トークン作成', true
      it_behaves_like '[ログイン中][期限内]確認日時がない（未確認）'
      it_behaves_like '[ログイン中][期限内]確認日時が確認送信日時より前（未確認）'
      it_behaves_like '[ログイン中][期限内]確認日時が確認送信日時より後（確認済み）'
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
