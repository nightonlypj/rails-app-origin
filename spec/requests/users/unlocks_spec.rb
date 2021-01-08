require 'rails_helper'

RSpec.describe 'Users::Unlocks', type: :request do
  # GET /users/unlock/new アカウントロック解除メール再送
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  describe 'GET /new' do
    # テスト内容
    shared_examples_for 'ToOK' do
      it '成功ステータス' do
        get new_user_unlock_path
        expect(response).to be_successful
      end
    end
    shared_examples_for 'ToTop' do |alert, notice|
      it 'トップページにリダイレクト' do
        get new_user_unlock_path
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end

    # テストケース
    context '未ログイン' do
      it_behaves_like 'ToOK'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
    end
  end

  # POST /users/unlock アカウントロック解除メール再送(処理)
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  #   有効なパラメータ, 無効なパラメータ → 事前にデータ作成
  describe 'POST /create' do
    include_context 'アカウントロック解除トークン作成'
    let!(:valid_attributes) { FactoryBot.attributes_for(:user, email: @send_user.email) }
    let!(:invalid_attributes) { FactoryBot.attributes_for(:user, email: nil) }

    # テスト内容
    shared_examples_for 'ToOK' do
      it '成功ステータス' do
        post user_unlock_path, params: { user: attributes }
        expect(response).to be_successful
      end
    end
    shared_examples_for 'ToTop' do |alert, notice|
      it 'トップページにリダイレクト' do
        post user_unlock_path, params: { user: attributes }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end
    shared_examples_for 'ToLogin' do |alert, notice|
      it 'ログインにリダイレクト' do
        post user_unlock_path, params: { user: attributes }
        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end

    # テストケース
    shared_examples_for '[未ログイン]有効なパラメータ' do
      let!(:attributes) { valid_attributes }
      it_behaves_like 'ToLogin', nil, 'devise.unlocks.send_instructions'
    end
    shared_examples_for '[ログイン中/削除予約済み]有効なパラメータ' do
      let!(:attributes) { valid_attributes }
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン]無効なパラメータ' do
      let!(:attributes) { invalid_attributes }
      it_behaves_like 'ToOK' # Tips: 再入力
    end
    shared_examples_for '[ログイン中/削除予約済み]無効なパラメータ' do
      let!(:attributes) { invalid_attributes }
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
    end

    context '未ログイン' do
      it_behaves_like '[未ログイン]有効なパラメータ'
      it_behaves_like '[未ログイン]無効なパラメータ'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[ログイン中/削除予約済み]有効なパラメータ'
      it_behaves_like '[ログイン中/削除予約済み]無効なパラメータ'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it_behaves_like '[ログイン中/削除予約済み]有効なパラメータ'
      it_behaves_like '[ログイン中/削除予約済み]無効なパラメータ'
    end
  end

  # GET /users/unlock アカウントロック解除(処理)
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  #   トークン: 存在する, 存在しない, ない → データ作成
  #   ロック日時: ない（未ロック）, ある（ロック中） → データ作成
  describe 'GET /show' do
    # テスト内容
    shared_examples_for 'OK' do
      it 'アカウントロック日時がなしに変更される' do
        get user_unlock_path(unlock_token: unlock_token)
        expect(User.find(@send_user.id).locked_at).to be_nil
      end
    end
    shared_examples_for 'NG' do
      it 'アカウントロック日時が変更されない' do
        get user_unlock_path(unlock_token: unlock_token)
        expect(User.find(@send_user.id).locked_at).to eq(@send_user.locked_at)
      end
    end

    shared_examples_for 'ToOK' do
      it '成功ステータス' do
        get user_unlock_path(unlock_token: unlock_token)
        expect(response).to be_successful
      end
    end
    shared_examples_for 'ToTop' do |alert, notice|
      it 'トップページにリダイレクト' do
        get user_unlock_path(unlock_token: unlock_token)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end
    shared_examples_for 'ToLogin' do |alert, notice|
      it 'ログインにリダイレクト' do
        get user_unlock_path(unlock_token: unlock_token)
        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end

    # テストケース
    shared_examples_for '[未ログイン][存在する]ロック日時がない（未ロック）' do
      include_context 'アカウントロック解除トークン解除'
      # it_behaves_like 'NG' # Tips: 元々、ロック日時がない
      it_behaves_like 'ToLogin', nil, 'devise.unlocks.unlocked' # Tips: 既に解除済み
    end
    shared_examples_for '[ログイン中/削除予約済み][存在する]ロック日時がない（未ロック）' do
      include_context 'アカウントロック解除トークン解除'
      # it_behaves_like 'NG' # Tips: 元々、ロック日時がない
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン][存在しない/ない]ロック日時がない（未ロック）' do
      # it_behaves_like 'NG' # Tips: トークンが存在しない為、ロック日時がない
      it_behaves_like 'ToOK' # Tips: 再入力
    end
    shared_examples_for '[ログイン中/削除予約済み][存在しない/ない]ロック日時がない（未ロック）' do
      # it_behaves_like 'NG' # Tips: トークンが存在しない為、ロック日時がない
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン][存在する]ロック日時がある（ロック中）' do
      it_behaves_like 'OK'
      it_behaves_like 'ToLogin', nil, 'devise.unlocks.unlocked'
    end
    shared_examples_for '[ログイン中/削除予約済み][存在する]ロック日時がある（ロック中）' do
      it_behaves_like 'NG'
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
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
