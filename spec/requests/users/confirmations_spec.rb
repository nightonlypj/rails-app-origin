require 'rails_helper'

RSpec.describe 'Users::Confirmations', type: :request do
  # GET /users/confirmation/new メールアドレス確認メール再送
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  describe 'GET /new' do
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

  # POST /users/confirmation メールアドレス確認メール再送(処理)
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  #   有効なパラメータ, 無効なパラメータ → 事前にデータ作成
  describe 'POST /create' do
    let!(:send_user) { FactoryBot.create(:user, confirmed_at: nil) }
    let!(:valid_attributes) { FactoryBot.attributes_for(:user, email: send_user.email) }
    let!(:invalid_attributes) { FactoryBot.attributes_for(:user, email: nil) }

    # テスト内容
    shared_examples_for 'ToOK' do
      it '成功ステータス' do
        post user_confirmation_path, params: { user: attributes }
        expect(response).to be_successful
      end
    end
    shared_examples_for 'ToLogin' do
      it 'ログインにリダイレクト' do
        post user_confirmation_path, params: { user: attributes }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    # テストケース
    shared_examples_for '有効なパラメータ' do # Tips: ログイン中も出来ても良さそう
      let!(:attributes) { valid_attributes }
      it_behaves_like 'ToLogin'
    end
    shared_examples_for '無効なパラメータ' do
      let!(:attributes) { invalid_attributes }
      it_behaves_like 'ToOK' # Tips: 再入力の為
    end

    context '未ログイン' do
      it_behaves_like '有効なパラメータ'
      it_behaves_like '無効なパラメータ'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '有効なパラメータ'
      it_behaves_like '無効なパラメータ'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it_behaves_like '有効なパラメータ'
      it_behaves_like '無効なパラメータ'
    end
  end

  # GET /users/confirmation メールアドレス確認(処理)
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  #   期限内のtoken, 期限切れのtoken, 存在しないtoken, tokenなし → データ作成
  #   未確認（確認日時がない）, 未確認（確認日時が確認送信日時より前）, 確認済み（確認日時が確認送信日時より後） → データ作成
  describe 'GET /show' do
    # テスト内容
    shared_examples_for 'OK' do
      let!(:start_time) { Time.now.utc }
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

    shared_examples_for 'ToTop' do
      it 'トップページにリダイレクト' do
        get user_confirmation_path(confirmation_token: confirmation_token)
        expect(response).to redirect_to(root_path)
      end
    end
    shared_examples_for 'ToLogin' do
      it 'ログインにリダイレクト' do
        get user_confirmation_path(confirmation_token: confirmation_token)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
    shared_examples_for 'ToNew' do
      it 'メールアドレス確認メール再送にリダイレクト' do
        get user_confirmation_path(confirmation_token: confirmation_token)
        expect(response).to redirect_to(new_user_confirmation_path)
      end
    end

    # テストケース
    shared_examples_for '[未ログイン][期限内のtoken]未確認（確認日時がない）' do
      it_behaves_like 'OK'
      it_behaves_like 'ToLogin'
    end
    shared_examples_for '[ログイン中][期限内のtoken]未確認（確認日時がない）' do # Tips: ログイン中も出来ても良さそう
      it_behaves_like 'OK'
      it_behaves_like 'ToTop'
    end
    shared_examples_for '[期限切れのtoken]未確認（確認日時がない）' do
      it_behaves_like 'NG'
      it_behaves_like 'ToNew'
    end
    shared_examples_for '[存在しないtoken]未確認（確認日時がない）' do
      # it_behaves_like 'NG' # Tips: tokenが存在しない為、確認日時がない
      it_behaves_like 'ToNew'
    end
    shared_examples_for '[未ログイン][期限内のtoken]未確認（確認日時が確認送信日時より前）' do
      include_context 'メールアドレス確認トークン確認', true
      it_behaves_like 'OK'
      it_behaves_like 'ToLogin'
    end
    shared_examples_for '[ログイン中][期限内のtoken]未確認（確認日時が確認送信日時より前）' do # Tips: ログイン中も出来ても良さそう
      include_context 'メールアドレス確認トークン確認', true
      it_behaves_like 'OK'
      it_behaves_like 'ToTop'
    end
    shared_examples_for '[期限切れのtoken]未確認（確認日時が確認送信日時より前）' do
      include_context 'メールアドレス確認トークン確認', true
      it_behaves_like 'NG'
      it_behaves_like 'ToNew'
    end
    shared_examples_for '[未ログイン][期限内のtoken]確認済み（確認日時が確認送信日時より後）' do
      include_context 'メールアドレス確認トークン確認', false
      it_behaves_like 'NG'
      it_behaves_like 'ToLogin'
    end
    shared_examples_for '[ログイン中][期限内のtoken]確認済み（確認日時が確認送信日時より後）' do
      include_context 'メールアドレス確認トークン確認', false
      it_behaves_like 'NG'
      it_behaves_like 'ToLogin' # Tips: ログインからトップにリダイレクト
    end
    shared_examples_for '[期限切れのtoken]確認済み（確認日時が確認送信日時より後）' do
      include_context 'メールアドレス確認トークン確認', false
      it_behaves_like 'NG'
      it_behaves_like 'ToNew'
    end

    shared_examples_for '[未ログイン]期限内のtoken' do
      include_context 'メールアドレス確認トークン作成', true
      it_behaves_like '[未ログイン][期限内のtoken]未確認（確認日時がない）'
      it_behaves_like '[未ログイン][期限内のtoken]未確認（確認日時が確認送信日時より前）'
      it_behaves_like '[未ログイン][期限内のtoken]確認済み（確認日時が確認送信日時より後）'
    end
    shared_examples_for '[ログイン中]期限内のtoken' do
      include_context 'メールアドレス確認トークン作成', true
      it_behaves_like '[ログイン中][期限内のtoken]未確認（確認日時がない）'
      it_behaves_like '[ログイン中][期限内のtoken]未確認（確認日時が確認送信日時より前）'
      it_behaves_like '[ログイン中][期限内のtoken]確認済み（確認日時が確認送信日時より後）'
    end
    shared_examples_for '期限切れのtoken' do
      include_context 'メールアドレス確認トークン作成', false
      it_behaves_like '[期限切れのtoken]未確認（確認日時がない）'
      it_behaves_like '[期限切れのtoken]未確認（確認日時が確認送信日時より前）'
      it_behaves_like '[期限切れのtoken]確認済み（確認日時が確認送信日時より後）'
    end
    shared_examples_for '存在しないtoken' do
      let!(:confirmation_token) { NOT_TOKEN }
      it_behaves_like '[存在しないtoken]未確認（確認日時がない）'
      # it_behaves_like '[存在しないtoken]未確認（確認日時が確認送信日時より前）' # Tips: tokenが存在しない為、確認日時がない
      # it_behaves_like '確認済み（確認日時が確認送信日時より後）' # Tips: tokenが存在しない為、確認日時がない
    end
    shared_examples_for 'tokenなし' do
      let!(:confirmation_token) { NO_TOKEN }
      it_behaves_like '[存在しないtoken]未確認（確認日時がない）'
      # it_behaves_like '[存在しないtoken]未確認（確認日時が確認送信日時より前）' # Tips: tokenが存在しない為、確認日時がない
      # it_behaves_like '確認済み（確認日時が確認送信日時より後）' # Tips: tokenが存在しない為、確認日時がない
    end

    context '未ログイン' do
      it_behaves_like '[未ログイン]期限内のtoken'
      it_behaves_like '期限切れのtoken'
      it_behaves_like '存在しないtoken'
      it_behaves_like 'tokenなし'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[ログイン中]期限内のtoken'
      it_behaves_like '期限切れのtoken'
      it_behaves_like '存在しないtoken'
      it_behaves_like 'tokenなし'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it_behaves_like '[ログイン中]期限内のtoken'
      it_behaves_like '期限切れのtoken'
      it_behaves_like '存在しないtoken'
      it_behaves_like 'tokenなし'
    end
  end
end
